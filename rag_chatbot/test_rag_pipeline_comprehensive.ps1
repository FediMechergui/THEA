# THEA RAG Pipeline Comprehensive Test Suite
# Tests all RAG functionality including chat, indexing, vector search, and integrations

$baseUrl = "http://localhost:8001"
$apiUrl = "$baseUrl/api/v1"
$nodeBackendUrl = "http://localhost:3000"
$chromaUrl = "http://localhost:8010"
$ollamaUrl = "http://localhost:11434"

# Test results tracking
$results = New-Object System.Collections.ArrayList
$testCount = 0
$passCount = 0

Write-Host "🚀 THEA RAG Pipeline Comprehensive Test Suite" -ForegroundColor Magenta
Write-Host "=" * 60 -ForegroundColor Magenta

function Test-Endpoint {
    param(
        [string]$TestName,
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers = @{},
        [string]$Body = $null,
        [int]$ExpectedStatusCode = 200,
        [int]$TimeoutSeconds = 60,
        [string]$ExpectedContent = $null
    )
    
    $global:testCount++
    Write-Host "`n=== Test $global:testCount: $TestName ===" -ForegroundColor Cyan
    Write-Host "Method: $Method | URL: $Url" -ForegroundColor Gray
    
    try {
        $params = @{
            Uri = $Url
            Method = $Method
            TimeoutSec = $TimeoutSeconds
            ErrorAction = 'Stop'
        }
        
        if ($Headers.Count -gt 0) {
            $params.Headers = $Headers
        }
        
        if ($Body) {
            $params.Body = $Body
            Write-Host "Body: $Body" -ForegroundColor Gray
        }
        
        $startTime = Get-Date
        $response = Invoke-WebRequest @params
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        $success = $response.StatusCode -eq $ExpectedStatusCode
        
        # Additional content validation
        if ($ExpectedContent -and $success) {
            $success = $response.Content -like "*$ExpectedContent*"
        }
        
        if ($success) {
            Write-Host "✅ PASS" -ForegroundColor Green
            Write-Host "Status: $($response.StatusCode) | Duration: ${duration}ms" -ForegroundColor Green
            $global:passCount++
        } else {
            Write-Host "❌ FAIL" -ForegroundColor Red
            Write-Host "Expected: $ExpectedStatusCode, Got: $($response.StatusCode)" -ForegroundColor Red
        }
        
        # Parse JSON response if possible
        $responseObj = $null
        try {
            $responseObj = $response.Content | ConvertFrom-Json
        } catch {}
        
        $global:results.Add([PSCustomObject]@{
            Test = $TestName
            Status = if ($success) { "PASS" } else { "FAIL" }
            StatusCode = $response.StatusCode
            Duration = "${duration}ms"
            ResponseSize = $response.Content.Length
            Response = if ($responseObj) { $responseObj } else { $response.Content }
        }) | Out-Null
        
        return $responseObj
        
    } catch {
        Write-Host "❌ ERROR" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        
        $global:results.Add([PSCustomObject]@{
            Test = $TestName
            Status = "ERROR"
            StatusCode = "N/A"
            Duration = "N/A"
            ResponseSize = 0
            Response = $_.Exception.Message
        }) | Out-Null
        
        return $null
    }
}

Write-Host "`n🔍 Phase 1: Infrastructure Health Checks" -ForegroundColor Yellow

# Test 1: RAG Chatbot Health
Test-Endpoint -TestName "RAG Chatbot Health Check" -Method "GET" -Url "$baseUrl/health"

# Test 2: Node.js Backend Health
Test-Endpoint -TestName "Node.js Backend Health Check" -Method "GET" -Url "$nodeBackendUrl/health"

# Test 3: ChromaDB Health
Test-Endpoint -TestName "ChromaDB Health Check" -Method "GET" -Url "$chromaUrl/api/v1/heartbeat"

# Test 4: Ollama Health
Test-Endpoint -TestName "Ollama Health Check" -Method "GET" -Url "$ollamaUrl/api/version"

Write-Host "`n🧠 Phase 2: AI/ML Components" -ForegroundColor Yellow

# Test 5: Ollama Model Status
$modelResponse = Test-Endpoint -TestName "Check Available Models" -Method "GET" -Url "$ollamaUrl/api/tags"

# Test 6: ChromaDB Collections
Test-Endpoint -TestName "List ChromaDB Collections" -Method "GET" -Url "$chromaUrl/api/v1/collections"

Write-Host "`n💬 Phase 3: RAG Chat Functionality" -ForegroundColor Yellow

$chatHeaders = @{"Content-Type" = "application/json"}

# Test 7: Simple Chat Query
$chatBody1 = @{
    query = "Hello, what is your purpose?"
    conversation_id = $null
    context = $null
} | ConvertTo-Json

$chatResponse1 = Test-Endpoint -TestName "Simple Chat Query" -Method "POST" -Url "$apiUrl/chat" -Headers $chatHeaders -Body $chatBody1 -TimeoutSeconds 120

# Test 8: Business Context Query
$chatBody2 = @{
    query = "What can you tell me about invoice processing?"
    conversation_id = $null
    context = @{
        domain = "business"
        type = "invoice"
    }
} | ConvertTo-Json

$chatResponse2 = Test-Endpoint -TestName "Business Context Query" -Method "POST" -Url "$apiUrl/chat" -Headers $chatHeaders -Body $chatBody2 -TimeoutSeconds 120

# Test 9: Conversation Continuation
if ($chatResponse1 -and $chatResponse1.conversation_id) {
    $chatBody3 = @{
        query = "Can you elaborate on that?"
        conversation_id = $chatResponse1.conversation_id
        context = $null
    } | ConvertTo-Json
    
    Test-Endpoint -TestName "Conversation Continuation" -Method "POST" -Url "$apiUrl/chat" -Headers $chatHeaders -Body $chatBody3 -TimeoutSeconds 120
}

Write-Host "`n📚 Phase 4: Data Indexing & Admin Functions" -ForegroundColor Yellow

$adminHeaders = @{"Content-Type" = "application/json"}

# Test 10: Start Data Indexing
$indexBody = @{
    data_type = "invoices"
    options = @{
        full_refresh = $false
    }
} | ConvertTo-Json

$indexResponse = Test-Endpoint -TestName "Start Data Indexing" -Method "POST" -Url "$apiUrl/admin/index" -Headers $adminHeaders -Body $indexBody

# Test 11: Check Indexing Status
if ($indexResponse -and $indexResponse.task_id) {
    Start-Sleep -Seconds 2
    Test-Endpoint -TestName "Check Indexing Status" -Method "GET" -Url "$apiUrl/admin/index/status/$($indexResponse.task_id)"
}

Write-Host "`n📖 Phase 5: Conversation History" -ForegroundColor Yellow

# Test 12: Get Conversation History
if ($chatResponse1 -and $chatResponse1.conversation_id) {
    Test-Endpoint -TestName "Get Conversation History" -Method "GET" -Url "$apiUrl/conversations/$($chatResponse1.conversation_id)"
}

Write-Host "`n🔧 Phase 6: Error Handling & Edge Cases" -ForegroundColor Yellow

# Test 13: Invalid Endpoint
Test-Endpoint -TestName "Invalid Endpoint (404)" -Method "GET" -Url "$apiUrl/nonexistent" -ExpectedStatusCode 404

# Test 14: Malformed Chat Request
$malformedBody = @"
{"invalid": "json"}
"@
Test-Endpoint -TestName "Malformed Request Body" -Method "POST" -Url "$apiUrl/chat" -Headers $chatHeaders -Body $malformedBody -ExpectedStatusCode 422

# Test 15: Empty Chat Query
$emptyBody = @{
    query = ""
    conversation_id = $null
    context = $null
} | ConvertTo-Json

Test-Endpoint -TestName "Empty Query Handling" -Method "POST" -Url "$apiUrl/chat" -Headers $chatHeaders -Body $emptyBody -ExpectedStatusCode 422 -TimeoutSeconds 60

Write-Host "`n📊 Phase 7: Performance & Load Tests" -ForegroundColor Yellow

# Test 16: Concurrent Requests Test
$jobs = @()
Write-Host "Starting 3 concurrent chat requests..." -ForegroundColor Gray

1..3 | ForEach-Object {
    $job = Start-Job -ScriptBlock {
        param($apiUrl, $testNum)
        
        $headers = @{"Content-Type" = "application/json"}
        $body = @{
            query = "Test query #$testNum for concurrent testing"
            conversation_id = $null
            context = $null
        } | ConvertTo-Json
        
        try {
            $response = Invoke-WebRequest -Uri "$apiUrl/chat" -Method POST -Headers $headers -Body $body -TimeoutSec 120
            return @{
                Success = $true
                StatusCode = $response.StatusCode
                TestNum = $testNum
            }
        } catch {
            return @{
                Success = $false
                Error = $_.Exception.Message
                TestNum = $testNum
            }
        }
    } -ArgumentList $apiUrl, $_
    
    $jobs += $job
}

# Wait for all jobs to complete
$jobResults = $jobs | Wait-Job | Receive-Job
$jobs | Remove-Job

$concurrentSuccess = ($jobResults | Where-Object { $_.Success }).Count
Write-Host "Concurrent Requests: $concurrentSuccess/3 successful" -ForegroundColor $(if ($concurrentSuccess -eq 3) { "Green" } else { "Yellow" })

Write-Host "`n📋 TEST SUMMARY" -ForegroundColor Magenta
Write-Host "=" * 60 -ForegroundColor Magenta
Write-Host "Total Tests: $testCount" -ForegroundColor White
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $($testCount - $passCount)" -ForegroundColor Red
Write-Host "Success Rate: $([math]::Round(($passCount / [math]::Max($testCount, 1)) * 100, 2))%" -ForegroundColor White
Write-Host "Concurrent Success Rate: $([math]::Round(($concurrentSuccess / 3) * 100, 2))%" -ForegroundColor White

Write-Host "`n📈 DETAILED RESULTS" -ForegroundColor Magenta
$results | Format-Table -AutoSize

# Export results
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$resultsFile = "rag_pipeline_test_results_$timestamp.csv"
$results | Export-Csv -Path $resultsFile -NoTypeInformation

# Summary JSON report
$summaryReport = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    total_tests = $testCount
    passed_tests = $passCount
    failed_tests = $testCount - $passCount
    success_rate = [math]::Round(($passCount / [math]::Max($testCount, 1)) * 100, 2)
    concurrent_success_rate = [math]::Round(($concurrentSuccess / 3) * 100, 2)
    test_results = $results
} | ConvertTo-Json -Depth 3

$summaryFile = "rag_pipeline_summary_$timestamp.json"
$summaryReport | Out-File -FilePath $summaryFile -Encoding UTF8

Write-Host "`n📁 Results exported to:" -ForegroundColor Green
Write-Host "  • CSV: $resultsFile" -ForegroundColor White
Write-Host "  • JSON: $summaryFile" -ForegroundColor White

Write-Host "`n🎯 RAG Pipeline Test Complete!" -ForegroundColor Magenta