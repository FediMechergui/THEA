# THEA RAG Pipeline Test Suite (Simplified)
# Tests all RAG functionality including chat, indexing, vector search, and integrations

$baseUrl = "http://localhost:8001"
$apiUrl = "$baseUrl/api/v1"
$nodeBackendUrl = "http://localhost:3000"
$chromaUrl = "http://localhost:8010"
$ollamaUrl = "http://localhost:11434"

# Test results tracking
$global:results = New-Object System.Collections.ArrayList
$global:testCount = 0
$global:passCount = 0

Write-Host "THEA RAG Pipeline Test Suite" -ForegroundColor Magenta
Write-Host "=" * 50 -ForegroundColor Magenta

function Test-Endpoint {
    param(
        [string]$TestName,
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers = @{},
        [string]$Body = $null,
        [int[]]$ExpectedStatusCodes = @(200),
        [int]$TimeoutSeconds = 60
    )
    
    $global:testCount++
    Write-Host "`n--- Test $global:testCount: $TestName ---" -ForegroundColor Cyan
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
        
        $success = $ExpectedStatusCodes -contains $response.StatusCode
        
        if ($success) {
            Write-Host "PASS" -ForegroundColor Green
            Write-Host "Status: $($response.StatusCode) | Duration: ${duration}ms" -ForegroundColor Green
            $global:passCount++
        } else {
            Write-Host "FAIL" -ForegroundColor Red
            Write-Host "Expected: $($ExpectedStatusCodes -join ', '), Got: $($response.StatusCode)" -ForegroundColor Red
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
            Response = if ($responseObj) { $responseObj } else { $response.Content.Substring(0, [Math]::Min($response.Content.Length, 100)) + "..." }
        }) | Out-Null
        
        return $responseObj
        
    } catch {
        $endTime = Get-Date
        $duration = if ($startTime) { ($endTime - $startTime).TotalMilliseconds } else { $null }
        $statusCode = $null
        $responseText = $null
        $responseObj = $null

        if ($_.Exception.Response) {
            try {
                $statusCode = [int]$_.Exception.Response.StatusCode
                $stream = $_.Exception.Response.GetResponseStream()
                if ($stream) {
                    $reader = New-Object System.IO.StreamReader($stream)
                    $responseText = $reader.ReadToEnd()
                    $reader.Close()
                }
            } catch {}
        }

        if (-not $responseText) {
            $responseText = $_.Exception.Message
        }

        if ($responseText) {
            try {
                $responseObj = $responseText | ConvertFrom-Json
            } catch {}
        }

        $success = $statusCode -ne $null -and ($ExpectedStatusCodes -contains $statusCode)

        if ($success) {
            Write-Host "PASS" -ForegroundColor Green
            Write-Host "Status: $statusCode | Duration: ${duration}ms" -ForegroundColor Green
            $global:passCount++
        } else {
            Write-Host "ERROR" -ForegroundColor Red
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        }

        $responsePreview = $responseText
        if ($responseText -and $responseText.Length -gt 100) {
            $responsePreview = $responseText.Substring(0, 100) + "..."
        }

        $global:results.Add([PSCustomObject]@{
            Test = $TestName
            Status = if ($success) { "PASS" } else { "ERROR" }
            StatusCode = if ($statusCode) { $statusCode } else { "N/A" }
            Duration = if ($duration) { "${duration}ms" } else { "N/A" }
            ResponseSize = if ($responseText) { $responseText.Length } else { 0 }
            Response = if ($responseObj) { $responseObj } elseif ($responsePreview) { $responsePreview } else { $_.Exception.Message }
        }) | Out-Null
        
        return $responseObj
    }
}

Write-Host "`nPhase 1: Infrastructure Health Checks" -ForegroundColor Yellow

# Test 1: RAG Chatbot Health
Test-Endpoint -TestName "RAG Chatbot Health Check" -Method "GET" -Url "$baseUrl/health"

# Test 2: Node.js Backend Health
Test-Endpoint -TestName "Node.js Backend Health Check" -Method "GET" -Url "$nodeBackendUrl/health"

# Test 3: ChromaDB Health
Test-Endpoint -TestName "ChromaDB Health Check" -Method "GET" -Url "$chromaUrl/api/v2/version"

# Test 4: Ollama Health
Test-Endpoint -TestName "Ollama Health Check" -Method "GET" -Url "$ollamaUrl/api/version"

Write-Host "`nPhase 2: AI/ML Components" -ForegroundColor Yellow

# Test 5: Ollama Model Status
$modelResponse = Test-Endpoint -TestName "Check Available Models" -Method "GET" -Url "$ollamaUrl/api/tags"

# Test 6: ChromaDB Collections
Test-Endpoint -TestName "List ChromaDB Collections" -Method "GET" -Url "$chromaUrl/api/v2/collections" -ExpectedStatusCodes @(200, 404)

Write-Host "`nPhase 3: RAG Chat Functionality" -ForegroundColor Yellow

$chatHeaders = @{"Content-Type" = "application/json"}

# Test 7: Simple Chat Query
$chatBody1 = @{
    query = "Hello, what is your purpose?"
    conversation_id = $null
    context = $null
} | ConvertTo-Json

Write-Host "Testing simple chat query..." -ForegroundColor Gray
$chatResponse1 = Test-Endpoint -TestName "Simple Chat Query" -Method "POST" -Url "$apiUrl/chat" -Headers $chatHeaders -Body $chatBody1 -TimeoutSeconds 240

# Test 8: Business Context Query
$chatBody2 = @{
    query = "What can you tell me about invoice processing?"
    conversation_id = $null
    context = @{
        domain = "business"
        type = "invoice"
    }
} | ConvertTo-Json

Write-Host "Testing business context query..." -ForegroundColor Gray
$chatResponse2 = Test-Endpoint -TestName "Business Context Query" -Method "POST" -Url "$apiUrl/chat" -Headers $chatHeaders -Body $chatBody2 -TimeoutSeconds 300

# Test 9: Conversation Continuation
if ($chatResponse1 -and $chatResponse1.conversation_id) {
    $chatBody3 = @{
        query = "Can you elaborate on that?"
        conversation_id = $chatResponse1.conversation_id
        context = $null
    } | ConvertTo-Json
    
    Write-Host "Testing conversation continuation..." -ForegroundColor Gray
    Test-Endpoint -TestName "Conversation Continuation" -Method "POST" -Url "$apiUrl/chat" -Headers $chatHeaders -Body $chatBody3 -TimeoutSeconds 240
}

Write-Host "`nPhase 4: Data Indexing & Admin Functions" -ForegroundColor Yellow

$adminHeaders = @{"Content-Type" = "application/json"}

# Test 10: Start Data Indexing
$indexBody = @{
    data_type = "test_documents"
    options = @{
        full_refresh = $false
        batch_size = 10
    }
} | ConvertTo-Json

Write-Host "Testing data indexing..." -ForegroundColor Gray
$indexResponse = Test-Endpoint -TestName "Start Data Indexing" -Method "POST" -Url "$apiUrl/admin/index" -Headers $adminHeaders -Body $indexBody -TimeoutSeconds 60

# Test 11: Check Indexing Status
if ($indexResponse -and $indexResponse.task_id) {
    Start-Sleep -Seconds 2
    Test-Endpoint -TestName "Check Indexing Status" -Method "GET" -Url "$apiUrl/admin/index/status/$($indexResponse.task_id)"
}

Write-Host "`nPhase 5: Conversation History" -ForegroundColor Yellow

# Test 12: Get Conversation History
if ($chatResponse1 -and $chatResponse1.conversation_id) {
    Test-Endpoint -TestName "Get Conversation History" -Method "GET" -Url "$apiUrl/conversations/$($chatResponse1.conversation_id)"
}

Write-Host "`nPhase 6: Error Handling" -ForegroundColor Yellow

# Test 13: Invalid Endpoint
Test-Endpoint -TestName "Invalid Endpoint (404)" -Method "GET" -Url "$apiUrl/nonexistent" -ExpectedStatusCodes @(404)

# Test 14: Empty Chat Query
$emptyBody = @{
    query = ""
    conversation_id = $null
    context = $null
} | ConvertTo-Json

Test-Endpoint -TestName "Empty Query Handling" -Method "POST" -Url "$apiUrl/chat" -Headers $chatHeaders -Body $emptyBody -ExpectedStatusCodes @(200) -TimeoutSeconds 30

Write-Host "`nTEST SUMMARY" -ForegroundColor Magenta
Write-Host "=" * 50 -ForegroundColor Magenta
Write-Host "Total Tests: $global:testCount" -ForegroundColor White
Write-Host "Passed: $global:passCount" -ForegroundColor Green
Write-Host "Failed: $($global:testCount - $global:passCount)" -ForegroundColor Red
$successRate = if ($global:testCount -gt 0) { [math]::Round(($global:passCount / $global:testCount) * 100, 2) } else { 0 }
Write-Host "Success Rate: $successRate%" -ForegroundColor White

Write-Host "`nDETAILED RESULTS" -ForegroundColor Magenta
$results | Format-Table -AutoSize

# Export results
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$resultsFile = "rag_test_results_$timestamp.csv"
$results | Export-Csv -Path $resultsFile -NoTypeInformation

# Summary JSON report
$summaryReport = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    total_tests = $testCount
    passed_tests = $passCount
    failed_tests = $testCount - $passCount
    success_rate = $successRate
    test_results = $results
} | ConvertTo-Json -Depth 3

$summaryFile = "rag_test_summary_$timestamp.json"
$summaryReport | Out-File -FilePath $summaryFile -Encoding UTF8

Write-Host "`nResults exported to:" -ForegroundColor Green
Write-Host "  CSV: $resultsFile" -ForegroundColor White
Write-Host "  JSON: $summaryFile" -ForegroundColor White

Write-Host "`nRAG Pipeline Test Complete!" -ForegroundColor Magenta

if ($successRate -ge 80) {
    Write-Host "Overall Status: SUCCESS" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Overall Status: NEEDS ATTENTION" -ForegroundColor Yellow
    exit 1
}