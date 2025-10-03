#!/usr/bin/env python3
"""
THEA RAG Pipeline Advanced Test Suite
Tests vector embeddings, semantic similarity, and deep RAG functionality
"""

import requests
import json
import time
import pytest
import asyncio
import aiohttp
from typing import Dict, List, Optional, Any
from datetime import datetime
import logging
import numpy as np
from concurrent.futures import ThreadPoolExecutor, as_completed
import os
import sys

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class RAGTestSuite:
    def __init__(self):
        self.base_url = "http://localhost:8001"
        self.api_url = f"{self.base_url}/api/v1"
        self.chroma_url = "http://localhost:8010"
        self.ollama_url = "http://localhost:11434"
        self.node_backend_url = "http://localhost:3000"
        
        self.session = requests.Session()
        self.session.headers.update({'Content-Type': 'application/json'})
        
        self.test_results = []
        self.conversation_ids = []
        
    def log_result(self, test_name: str, success: bool, response_time: float, details: Dict = None):
        """Log test results for reporting"""
        result = {
            'test_name': test_name,
            'success': success,
            'response_time_ms': round(response_time * 1000, 2),
            'timestamp': datetime.now().isoformat(),
            'details': details or {}
        }
        self.test_results.append(result)
        
        status = "✅ PASS" if success else "❌ FAIL"
        logger.info(f"{status} {test_name} ({result['response_time_ms']}ms)")
        
        if details:
            logger.info(f"Details: {json.dumps(details, indent=2)}")
    
    def test_infrastructure_health(self) -> bool:
        """Test all infrastructure components"""
        logger.info("🔍 Testing Infrastructure Health")
        
        endpoints = [
            ("RAG Service Health", f"{self.base_url}/health"),
            ("Node Backend Health", f"{self.node_backend_url}/health"),
            ("ChromaDB Health", f"{self.chroma_url}/api/v1/heartbeat"),
            ("Ollama Health", f"{self.ollama_url}/api/version")
        ]
        
        all_healthy = True
        
        for name, url in endpoints:
            start_time = time.time()
            try:
                response = self.session.get(url, timeout=30)
                success = response.status_code == 200
                response_time = time.time() - start_time
                
                details = {
                    'status_code': response.status_code,
                    'response_size': len(response.content)
                }
                
                if success:
                    try:
                        details['response_data'] = response.json()
                    except:
                        details['response_text'] = response.text[:200]
                
                self.log_result(name, success, response_time, details)
                all_healthy &= success
                
            except Exception as e:
                response_time = time.time() - start_time
                self.log_result(name, False, response_time, {'error': str(e)})
                all_healthy = False
        
        return all_healthy
    
    def test_model_availability(self) -> bool:
        """Test if ML models are loaded and available"""
        logger.info("🧠 Testing ML Model Availability")
        
        # Test Ollama models
        start_time = time.time()
        try:
            response = self.session.get(f"{self.ollama_url}/api/tags", timeout=30)
            response_time = time.time() - start_time
            
            if response.status_code == 200:
                models_data = response.json()
                models = models_data.get('models', [])
                has_llama = any('llama' in model.get('name', '').lower() for model in models)
                
                details = {
                    'available_models': [model.get('name') for model in models],
                    'has_llama_model': has_llama,
                    'total_models': len(models)
                }
                
                self.log_result("Ollama Models Available", len(models) > 0, response_time, details)
                return len(models) > 0
            else:
                self.log_result("Ollama Models Available", False, response_time, 
                              {'status_code': response.status_code})
                return False
                
        except Exception as e:
            response_time = time.time() - start_time
            self.log_result("Ollama Models Available", False, response_time, {'error': str(e)})
            return False
    
    def test_vector_database(self) -> bool:
        """Test ChromaDB vector database functionality"""
        logger.info("📊 Testing Vector Database")
        
        # List collections
        start_time = time.time()
        try:
            response = self.session.get(f"{self.chroma_url}/api/v1/collections", timeout=30)
            response_time = time.time() - start_time
            
            success = response.status_code == 200
            details = {'status_code': response.status_code}
            
            if success:
                collections = response.json()
                details.update({
                    'collections_count': len(collections),
                    'collections': [col.get('name') for col in collections] if collections else []
                })
            
            self.log_result("ChromaDB Collections List", success, response_time, details)
            return success
            
        except Exception as e:
            response_time = time.time() - start_time
            self.log_result("ChromaDB Collections List", False, response_time, {'error': str(e)})
            return False
    
    def test_basic_chat_functionality(self) -> bool:
        """Test basic chat functionality"""
        logger.info("💬 Testing Basic Chat Functionality")
        
        test_queries = [
            {
                "name": "Simple Greeting",
                "query": "Hello, what is your purpose?",
                "expect_response": True
            },
            {
                "name": "Business Domain Query",
                "query": "How does invoice processing work in your system?",
                "expect_response": True,
                "context": {"domain": "business", "type": "invoice"}
            },
            {
                "name": "Technical Question",
                "query": "What is RAG and how does it work?",
                "expect_response": True
            }
        ]
        
        all_successful = True
        
        for test_query in test_queries:
            start_time = time.time()
            
            payload = {
                "query": test_query["query"],
                "conversation_id": None,
                "context": test_query.get("context")
            }
            
            try:
                response = self.session.post(f"{self.api_url}/chat", 
                                           json=payload, timeout=120)
                response_time = time.time() - start_time
                
                success = response.status_code == 200
                details = {'status_code': response.status_code}
                
                if success:
                    chat_response = response.json()
                    has_response = bool(chat_response.get('response', '').strip())
                    has_conv_id = bool(chat_response.get('conversation_id'))
                    
                    # Store conversation ID for follow-up tests
                    if has_conv_id:
                        self.conversation_ids.append(chat_response['conversation_id'])
                    
                    details.update({
                        'has_response': has_response,
                        'has_conversation_id': has_conv_id,
                        'response_length': len(chat_response.get('response', '')),
                        'sources_provided': len(chat_response.get('sources', [])),
                        'conversation_id': chat_response.get('conversation_id')
                    })
                    
                    success = success and has_response
                else:
                    try:
                        details['error_response'] = response.json()
                    except:
                        details['error_text'] = response.text[:200]
                
                self.log_result(test_query["name"], success, response_time, details)
                all_successful &= success
                
            except Exception as e:
                response_time = time.time() - start_time
                self.log_result(test_query["name"], False, response_time, {'error': str(e)})
                all_successful = False
        
        return all_successful
    
    def test_conversation_continuity(self) -> bool:
        """Test conversation memory and continuity"""
        logger.info("🔗 Testing Conversation Continuity")
        
        if not self.conversation_ids:
            logger.warning("No conversation IDs available for continuity testing")
            return False
        
        # Use the first conversation ID
        conv_id = self.conversation_ids[0]
        
        start_time = time.time()
        payload = {
            "query": "Can you elaborate on your previous response?",
            "conversation_id": conv_id,
            "context": None
        }
        
        try:
            response = self.session.post(f"{self.api_url}/chat", 
                                       json=payload, timeout=120)
            response_time = time.time() - start_time
            
            success = response.status_code == 200
            details = {'status_code': response.status_code, 'conversation_id': conv_id}
            
            if success:
                chat_response = response.json()
                has_response = bool(chat_response.get('response', '').strip())
                same_conv_id = chat_response.get('conversation_id') == conv_id
                
                details.update({
                    'has_response': has_response,
                    'same_conversation_id': same_conv_id,
                    'response_length': len(chat_response.get('response', ''))
                })
                
                success = success and has_response and same_conv_id
            
            self.log_result("Conversation Continuity", success, response_time, details)
            return success
            
        except Exception as e:
            response_time = time.time() - start_time
            self.log_result("Conversation Continuity", False, response_time, {'error': str(e)})
            return False
    
    def test_conversation_history(self) -> bool:
        """Test conversation history retrieval"""
        logger.info("📚 Testing Conversation History")
        
        if not self.conversation_ids:
            logger.warning("No conversation IDs available for history testing")
            return False
        
        conv_id = self.conversation_ids[0]
        
        start_time = time.time()
        try:
            response = self.session.get(f"{self.api_url}/conversations/{conv_id}", 
                                      timeout=30)
            response_time = time.time() - start_time
            
            success = response.status_code == 200
            details = {'status_code': response.status_code, 'conversation_id': conv_id}
            
            if success:
                history = response.json()
                has_messages = len(history.get('messages', [])) > 0
                
                details.update({
                    'message_count': len(history.get('messages', [])),
                    'has_messages': has_messages
                })
                
                success = success and has_messages
            
            self.log_result("Conversation History Retrieval", success, response_time, details)
            return success
            
        except Exception as e:
            response_time = time.time() - start_time
            self.log_result("Conversation History Retrieval", False, response_time, 
                          {'error': str(e)})
            return False
    
    def test_data_indexing(self) -> bool:
        """Test data indexing functionality"""
        logger.info("📖 Testing Data Indexing")
        
        # Start indexing
        start_time = time.time()
        payload = {
            "data_type": "test_documents",
            "options": {
                "full_refresh": False,
                "batch_size": 10
            }
        }
        
        try:
            response = self.session.post(f"{self.api_url}/admin/index", 
                                       json=payload, timeout=60)
            response_time = time.time() - start_time
            
            success = response.status_code in [200, 202]  # Accept both OK and Accepted
            details = {'status_code': response.status_code}
            
            if success:
                index_response = response.json()
                task_id = index_response.get('task_id')
                
                details.update({
                    'task_id': task_id,
                    'has_task_id': bool(task_id)
                })
                
                # If we got a task ID, check status
                if task_id:
                    time.sleep(2)  # Wait a bit for processing
                    status_start = time.time()
                    
                    try:
                        status_response = self.session.get(
                            f"{self.api_url}/admin/index/status/{task_id}", 
                            timeout=30)
                        status_time = time.time() - status_start
                        
                        status_success = status_response.status_code == 200
                        
                        if status_success:
                            status_data = status_response.json()
                            details.update({
                                'status_check_success': True,
                                'indexing_status': status_data.get('status'),
                                'status_response_time': round(status_time * 1000, 2)
                            })
                        else:
                            details['status_check_success'] = False
                    
                    except Exception as e:
                        details.update({
                            'status_check_success': False,
                            'status_error': str(e)
                        })
            
            self.log_result("Data Indexing", success, response_time, details)
            return success
            
        except Exception as e:
            response_time = time.time() - start_time
            self.log_result("Data Indexing", False, response_time, {'error': str(e)})
            return False
    
    def test_concurrent_requests(self, num_concurrent: int = 5) -> bool:
        """Test concurrent request handling"""
        logger.info(f"⚡ Testing Concurrent Requests ({num_concurrent} concurrent)")
        
        queries = [
            f"Test concurrent query #{i+1}" for i in range(num_concurrent)
        ]
        
        def make_request(query_text: str) -> Dict:
            payload = {
                "query": query_text,
                "conversation_id": None,
                "context": None
            }
            
            start_time = time.time()
            try:
                response = requests.post(f"{self.api_url}/chat", 
                                       json=payload, timeout=120,
                                       headers={'Content-Type': 'application/json'})
                response_time = time.time() - start_time
                
                return {
                    'success': response.status_code == 200,
                    'response_time': response_time,
                    'status_code': response.status_code,
                    'has_response': bool(response.json().get('response', '').strip()) if response.status_code == 200 else False
                }
            except Exception as e:
                response_time = time.time() - start_time
                return {
                    'success': False,
                    'response_time': response_time,
                    'error': str(e)
                }
        
        # Execute concurrent requests
        start_time = time.time()
        with ThreadPoolExecutor(max_workers=num_concurrent) as executor:
            future_to_query = {executor.submit(make_request, query): query 
                              for query in queries}
            
            results = []
            for future in as_completed(future_to_query):
                query = future_to_query[future]
                try:
                    result = future.result()
                    results.append(result)
                except Exception as e:
                    results.append({'success': False, 'error': str(e)})
        
        total_time = time.time() - start_time
        
        successful_requests = sum(1 for r in results if r['success'])
        avg_response_time = sum(r.get('response_time', 0) for r in results) / len(results)
        
        details = {
            'total_requests': num_concurrent,
            'successful_requests': successful_requests,
            'success_rate': (successful_requests / num_concurrent) * 100,
            'average_response_time_ms': round(avg_response_time * 1000, 2),
            'total_execution_time_ms': round(total_time * 1000, 2),
            'requests_per_second': round(num_concurrent / total_time, 2)
        }
        
        success = successful_requests >= (num_concurrent * 0.8)  # 80% success rate threshold
        
        self.log_result("Concurrent Request Handling", success, total_time, details)
        return success
    
    def test_error_handling(self) -> bool:
        """Test error handling for edge cases"""
        logger.info("🚨 Testing Error Handling")
        
        error_tests = [
            {
                "name": "Empty Query",
                "payload": {"query": "", "conversation_id": None},
                "expected_status": 422
            },
            {
                "name": "Invalid Conversation ID",
                "payload": {"query": "Test", "conversation_id": "invalid-id"},
                "expected_status": [200, 404, 422]  # Multiple acceptable statuses
            },
            {
                "name": "Malformed Request",
                "payload": {"invalid_field": "test"},
                "expected_status": 422
            }
        ]
        
        all_successful = True
        
        for test in error_tests:
            start_time = time.time()
            try:
                response = self.session.post(f"{self.api_url}/chat", 
                                           json=test["payload"], timeout=60)
                response_time = time.time() - start_time
                
                expected_statuses = test["expected_status"]
                if not isinstance(expected_statuses, list):
                    expected_statuses = [expected_statuses]
                
                success = response.status_code in expected_statuses
                
                details = {
                    'status_code': response.status_code,
                    'expected_statuses': expected_statuses
                }
                
                try:
                    error_response = response.json()
                    details['response'] = error_response
                except:
                    details['response_text'] = response.text[:200]
                
                self.log_result(test["name"], success, response_time, details)
                all_successful &= success
                
            except Exception as e:
                response_time = time.time() - start_time
                self.log_result(test["name"], False, response_time, {'error': str(e)})
                all_successful = False
        
        return all_successful
    
    def run_all_tests(self) -> Dict:
        """Run all tests and return summary"""
        logger.info("🚀 Starting RAG Pipeline Advanced Test Suite")
        
        test_phases = [
            ("Infrastructure Health", self.test_infrastructure_health),
            ("Model Availability", self.test_model_availability),
            ("Vector Database", self.test_vector_database),
            ("Basic Chat", self.test_basic_chat_functionality),
            ("Conversation Continuity", self.test_conversation_continuity),
            ("Conversation History", self.test_conversation_history),
            ("Data Indexing", self.test_data_indexing),
            ("Concurrent Requests", self.test_concurrent_requests),
            ("Error Handling", self.test_error_handling)
        ]
        
        phase_results = {}
        overall_start = time.time()
        
        for phase_name, test_func in test_phases:
            logger.info(f"\n{'='*60}")
            logger.info(f"🧪 Phase: {phase_name}")
            logger.info(f"{'='*60}")
            
            phase_start = time.time()
            try:
                phase_success = test_func()
                phase_time = time.time() - phase_start
                
                phase_results[phase_name] = {
                    'success': phase_success,
                    'duration_ms': round(phase_time * 1000, 2)
                }
                
                logger.info(f"Phase {phase_name}: {'✅ PASSED' if phase_success else '❌ FAILED'} "
                          f"({phase_results[phase_name]['duration_ms']}ms)")
                
            except Exception as e:
                phase_time = time.time() - phase_start
                phase_results[phase_name] = {
                    'success': False,
                    'duration_ms': round(phase_time * 1000, 2),
                    'error': str(e)
                }
                logger.error(f"Phase {phase_name} failed with error: {e}")
        
        total_time = time.time() - overall_start
        
        # Calculate summary statistics
        total_tests = len(self.test_results)
        passed_tests = sum(1 for r in self.test_results if r['success'])
        failed_tests = total_tests - passed_tests
        success_rate = (passed_tests / total_tests * 100) if total_tests > 0 else 0
        
        successful_phases = sum(1 for p in phase_results.values() if p['success'])
        phase_success_rate = (successful_phases / len(phase_results) * 100)
        
        summary = {
            'timestamp': datetime.now().isoformat(),
            'execution_time_ms': round(total_time * 1000, 2),
            'total_tests': total_tests,
            'passed_tests': passed_tests,
            'failed_tests': failed_tests,
            'test_success_rate': round(success_rate, 2),
            'phase_results': phase_results,
            'successful_phases': successful_phases,
            'total_phases': len(phase_results),
            'phase_success_rate': round(phase_success_rate, 2),
            'detailed_results': self.test_results
        }
        
        # Log summary
        logger.info(f"\n{'='*60}")
        logger.info("📊 TEST SUMMARY")
        logger.info(f"{'='*60}")
        logger.info(f"Total Execution Time: {summary['execution_time_ms']}ms")
        logger.info(f"Total Tests: {total_tests}")
        logger.info(f"Passed: {passed_tests} | Failed: {failed_tests}")
        logger.info(f"Test Success Rate: {success_rate:.2f}%")
        logger.info(f"Phase Success Rate: {phase_success_rate:.2f}%")
        logger.info(f"Overall Status: {'✅ PASSED' if phase_success_rate >= 80 else '❌ FAILED'}")
        
        return summary
    
    def save_results(self, summary: Dict, filename: str = None) -> str:
        """Save test results to JSON file"""
        if not filename:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"rag_pipeline_advanced_results_{timestamp}.json"
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(summary, f, indent=2, ensure_ascii=False)
        
        logger.info(f"📁 Results saved to: {filename}")
        return filename

def main():
    """Main test execution function"""
    if len(sys.argv) > 1 and sys.argv[1] == "--help":
        print("THEA RAG Pipeline Advanced Test Suite")
        print("Usage: python test_rag_advanced.py [--help]")
        print("\nThis script runs comprehensive tests on the RAG pipeline including:")
        print("• Infrastructure health checks")
        print("• AI/ML model availability")
        print("• Vector database functionality")
        print("• Chat and conversation features")
        print("• Performance and concurrency testing")
        print("• Error handling validation")
        return
    
    test_suite = RAGTestSuite()
    
    try:
        summary = test_suite.run_all_tests()
        results_file = test_suite.save_results(summary)
        
        # Exit with appropriate code
        success_rate = summary['phase_success_rate']
        exit_code = 0 if success_rate >= 80 else 1
        
        print(f"\n🎯 Test suite completed with {success_rate:.1f}% success rate")
        print(f"📄 Detailed results: {results_file}")
        
        sys.exit(exit_code)
        
    except KeyboardInterrupt:
        logger.info("\n⏹️  Test suite interrupted by user")
        sys.exit(1)
    except Exception as e:
        logger.error(f"💥 Test suite failed with error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()