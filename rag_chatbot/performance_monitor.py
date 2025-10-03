#!/usr/bin/env python3
"""
RAG Pipeline Performance Monitor
Real-time monitoring of RAG service performance and resource usage
"""

import requests
import time
import json
import psutil
import docker
from datetime import datetime, timedelta
import threading
import signal
import sys
from typing import Dict, List
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class RAGPerformanceMonitor:
    def __init__(self):
        self.base_url = "http://localhost:8001"
        self.api_url = f"{self.base_url}/api/v1"
        self.monitoring = False
        self.metrics = []
        
        # Initialize Docker client
        try:
            self.docker_client = docker.from_env()
        except Exception as e:
            logger.warning(f"Docker client unavailable: {e}")
            self.docker_client = None
    
    def get_system_metrics(self) -> Dict:
        """Get system resource metrics"""
        try:
            return {
                'cpu_percent': psutil.cpu_percent(interval=1),
                'memory': psutil.virtual_memory()._asdict(),
                'disk': psutil.disk_usage('/')._asdict(),
                'network': psutil.net_io_counters()._asdict()
            }
        except Exception as e:
            logger.error(f"Error getting system metrics: {e}")
            return {}
    
    def get_docker_metrics(self) -> Dict:
        """Get Docker container metrics for RAG services"""
        if not self.docker_client:
            return {}
        
        try:
            containers = self.docker_client.containers.list()
            rag_containers = [c for c in containers if 'rag' in c.name.lower() or 
                            'ollama' in c.name.lower() or 'chroma' in c.name.lower()]
            
            metrics = {}
            for container in rag_containers:
                try:
                    stats = container.stats(stream=False)
                    
                    # Calculate CPU percentage
                    cpu_delta = stats['cpu_stats']['cpu_usage']['total_usage'] - \
                               stats['precpu_stats']['cpu_usage']['total_usage']
                    system_delta = stats['cpu_stats']['system_cpu_usage'] - \
                                  stats['precpu_stats']['system_cpu_usage']
                    cpu_percent = (cpu_delta / system_delta) * len(stats['cpu_stats']['cpu_usage']['percpu_usage']) * 100.0
                    
                    # Memory usage
                    memory_usage = stats['memory_stats']['usage']
                    memory_limit = stats['memory_stats']['limit']
                    memory_percent = (memory_usage / memory_limit) * 100.0
                    
                    metrics[container.name] = {
                        'cpu_percent': round(cpu_percent, 2),
                        'memory_usage_mb': round(memory_usage / 1024 / 1024, 2),
                        'memory_limit_mb': round(memory_limit / 1024 / 1024, 2),
                        'memory_percent': round(memory_percent, 2),
                        'status': container.status
                    }
                except Exception as e:
                    logger.error(f"Error getting stats for {container.name}: {e}")
                    metrics[container.name] = {'error': str(e)}
            
            return metrics
        except Exception as e:
            logger.error(f"Error getting Docker metrics: {e}")
            return {}
    
    def test_response_time(self, endpoint: str, payload: Dict = None) -> Dict:
        """Test response time for a specific endpoint"""
        start_time = time.time()
        
        try:
            if payload:
                response = requests.post(endpoint, json=payload, timeout=60)
            else:
                response = requests.get(endpoint, timeout=30)
            
            response_time = time.time() - start_time
            
            return {
                'success': response.status_code == 200,
                'response_time_ms': round(response_time * 1000, 2),
                'status_code': response.status_code,
                'response_size': len(response.content)
            }
        except Exception as e:
            response_time = time.time() - start_time
            return {
                'success': False,
                'response_time_ms': round(response_time * 1000, 2),
                'error': str(e)
            }
    
    def collect_metrics(self) -> Dict:
        """Collect comprehensive performance metrics"""
        timestamp = datetime.now()
        
        # System metrics
        system_metrics = self.get_system_metrics()
        
        # Docker metrics
        docker_metrics = self.get_docker_metrics()
        
        # API response times
        health_test = self.test_response_time(f"{self.base_url}/health")
        
        chat_payload = {
            "query": "Performance test query",
            "conversation_id": None,
            "context": None
        }
        chat_test = self.test_response_time(f"{self.api_url}/chat", chat_payload)
        
        return {
            'timestamp': timestamp.isoformat(),
            'system': system_metrics,
            'docker_containers': docker_metrics,
            'api_performance': {
                'health_endpoint': health_test,
                'chat_endpoint': chat_test
            }
        }
    
    def start_monitoring(self, interval_seconds: int = 30, duration_minutes: int = 10):
        """Start continuous monitoring"""
        logger.info(f"🔍 Starting RAG Performance Monitor")
        logger.info(f"Interval: {interval_seconds}s | Duration: {duration_minutes}min")
        
        self.monitoring = True
        end_time = datetime.now() + timedelta(minutes=duration_minutes)
        
        try:
            while self.monitoring and datetime.now() < end_time:
                metrics = self.collect_metrics()
                self.metrics.append(metrics)
                
                # Log current status
                system = metrics.get('system', {})
                api_perf = metrics.get('api_performance', {})
                
                logger.info(f"CPU: {system.get('cpu_percent', 0):.1f}% | "
                          f"RAM: {system.get('memory', {}).get('percent', 0):.1f}% | "
                          f"Health: {api_perf.get('health_endpoint', {}).get('response_time_ms', 0)}ms | "
                          f"Chat: {api_perf.get('chat_endpoint', {}).get('response_time_ms', 0)}ms")
                
                if self.monitoring:
                    time.sleep(interval_seconds)
        
        except KeyboardInterrupt:
            logger.info("Monitoring stopped by user")
        finally:
            self.monitoring = False
    
    def generate_report(self) -> Dict:
        """Generate performance analysis report"""
        if not self.metrics:
            return {'error': 'No metrics collected'}
        
        # Calculate averages and trends
        cpu_values = [m.get('system', {}).get('cpu_percent', 0) for m in self.metrics]
        memory_values = [m.get('system', {}).get('memory', {}).get('percent', 0) for m in self.metrics]
        
        health_times = [m.get('api_performance', {}).get('health_endpoint', {}).get('response_time_ms', 0) 
                       for m in self.metrics]
        chat_times = [m.get('api_performance', {}).get('chat_endpoint', {}).get('response_time_ms', 0) 
                     for m in self.metrics]
        
        # Filter out zero values for chat times (failed requests)
        chat_times_success = [t for t in chat_times if t > 0]
        
        report = {
            'monitoring_period': {
                'start_time': self.metrics[0]['timestamp'],
                'end_time': self.metrics[-1]['timestamp'],
                'total_samples': len(self.metrics)
            },
            'system_performance': {
                'cpu': {
                    'average': round(sum(cpu_values) / len(cpu_values), 2),
                    'max': max(cpu_values),
                    'min': min(cpu_values)
                },
                'memory': {
                    'average': round(sum(memory_values) / len(memory_values), 2),
                    'max': max(memory_values),
                    'min': min(memory_values)
                }
            },
            'api_performance': {
                'health_endpoint': {
                    'average_ms': round(sum(health_times) / len(health_times), 2),
                    'max_ms': max(health_times),
                    'min_ms': min(health_times)
                },
                'chat_endpoint': {
                    'average_ms': round(sum(chat_times_success) / len(chat_times_success), 2) if chat_times_success else 0,
                    'max_ms': max(chat_times_success) if chat_times_success else 0,
                    'min_ms': min(chat_times_success) if chat_times_success else 0,
                    'success_rate': round(len(chat_times_success) / len(chat_times) * 100, 2)
                }
            }
        }
        
        # Add Docker container analysis if available
        docker_data = {}
        for metric in self.metrics:
            containers = metric.get('docker_containers', {})
            for container_name, stats in containers.items():
                if 'error' not in stats:
                    if container_name not in docker_data:
                        docker_data[container_name] = {'cpu': [], 'memory': []}
                    
                    docker_data[container_name]['cpu'].append(stats.get('cpu_percent', 0))
                    docker_data[container_name]['memory'].append(stats.get('memory_percent', 0))
        
        if docker_data:
            container_report = {}
            for container_name, data in docker_data.items():
                container_report[container_name] = {
                    'cpu': {
                        'average': round(sum(data['cpu']) / len(data['cpu']), 2),
                        'max': max(data['cpu']),
                        'min': min(data['cpu'])
                    },
                    'memory': {
                        'average': round(sum(data['memory']) / len(data['memory']), 2),
                        'max': max(data['memory']),
                        'min': min(data['memory'])
                    }
                }
            
            report['container_performance'] = container_report
        
        return report
    
    def save_results(self, filename: str = None) -> str:
        """Save monitoring results to file"""
        if not filename:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"rag_performance_monitor_{timestamp}.json"
        
        report = self.generate_report()
        
        results = {
            'report': report,
            'raw_metrics': self.metrics
        }
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        
        logger.info(f"📁 Performance results saved to: {filename}")
        return filename

def signal_handler(signum, frame):
    """Handle interrupt signals"""
    print("\n⏹️  Monitoring interrupted")
    sys.exit(0)

def main():
    """Main monitoring function"""
    signal.signal(signal.SIGINT, signal_handler)
    
    if len(sys.argv) > 1 and sys.argv[1] == "--help":
        print("RAG Pipeline Performance Monitor")
        print("Usage: python performance_monitor.py [interval_seconds] [duration_minutes]")
        print("\nDefault: 30 second intervals for 10 minutes")
        print("\nMonitors:")
        print("• System CPU and memory usage")
        print("• Docker container resource usage")
        print("• API response times")
        print("• Service health status")
        return
    
    # Parse command line arguments
    interval = 30
    duration = 10
    
    if len(sys.argv) >= 2:
        try:
            interval = int(sys.argv[1])
        except ValueError:
            print("Invalid interval, using default 30 seconds")
    
    if len(sys.argv) >= 3:
        try:
            duration = int(sys.argv[2])
        except ValueError:
            print("Invalid duration, using default 10 minutes")
    
    monitor = RAGPerformanceMonitor()
    
    try:
        monitor.start_monitoring(interval, duration)
        
        # Generate and display report
        report = monitor.generate_report()
        
        print("\n" + "="*60)
        print("📊 PERFORMANCE REPORT")
        print("="*60)
        
        if 'error' in report:
            print(f"❌ {report['error']}")
        else:
            period = report['monitoring_period']
            system = report['system_performance']
            api = report['api_performance']
            
            print(f"Monitoring Period: {period['total_samples']} samples")
            print(f"System CPU: {system['cpu']['average']}% avg, {system['cpu']['max']}% max")
            print(f"System Memory: {system['memory']['average']}% avg, {system['memory']['max']}% max")
            print(f"Health Endpoint: {api['health_endpoint']['average_ms']}ms avg")
            print(f"Chat Endpoint: {api['chat_endpoint']['average_ms']}ms avg, {api['chat_endpoint']['success_rate']}% success")
            
            if 'container_performance' in report:
                print(f"\n📦 Container Performance:")
                for name, stats in report['container_performance'].items():
                    print(f"  {name}: CPU {stats['cpu']['average']}%, RAM {stats['memory']['average']}%")
        
        # Save results
        results_file = monitor.save_results()
        print(f"\n📄 Detailed results: {results_file}")
        
    except Exception as e:
        logger.error(f"💥 Monitoring failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()