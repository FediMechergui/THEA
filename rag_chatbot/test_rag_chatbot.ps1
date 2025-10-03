# RAG Chatbot API Testing Script
# Tests all major endpoints and functionality

$baseUrl = "http://localhost:8001"
$apiUrl = "$baseUrl/api/v1"

# Test results tracking
$results = New-Object System.Collections.ArrayList
$testCount = 0
$passCount = 0

function Test-Endpoint {
    param(
        [string]$TestName,
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers = @{},
        [string]$Body = $null,
        [int]$ExpectedStatusCode = 200,
        [int]$TimeoutSeconds = 30
    )
    
    $global:testCount++
    Write-Host "`n=== Test $global:testCount: $TestName ===" -ForegroundColor Cyan
    Write-Host "Method: $Method" -ForegroundColor Gray
    Write-Host "URL: $Url" -ForegroundColor Gray
    
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
        
        if ($success) {
            Write-Host "✅ PASS" -ForegroundColor Green
            Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
            Write-Host "Duration: ${duration}ms" -ForegroundColor Green
            Write-Host "Response: $($response.Content)" -ForegroundColor Green
            $global:passCount++
        } else {
            Write-Host "❌ FAIL" -ForegroundColor Red
            Write-Host "Expected: $ExpectedStatusCode, Got: $($response.StatusCode)" -ForegroundColor Red
            Write-Host "Response: $($response.Content)" -ForegroundColor Red
        }
        
        $global:results.Add([PSCustomObject]@{
            Test = $TestName
            Status = if ($success) { "PASS" } else { "FAIL" }
            StatusCode = $response.StatusCode
            Duration = "${duration}ms"
            Response = $response.Content
        }) | Out-Null
        
    } catch {
        Write-Host "❌ ERROR" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        
        $global:results.Add([PSCustomObject]@{
            Test = $TestName
            Status = "ERROR"
            StatusCode = "N/A"
            Duration = "N/A"
            Response = $_.Exception.Message
        }) | Out-Null
    }
}

# Test 1: Health Check
Test-Endpoint -TestName "Health Check" -Method "GET" -Url "$baseUrl/health"

# Test 2: Chat Endpoint - Simple Query
$chatHeaders = @{'Content-Type' = 'application/json'}
$chatBody = '{"query": "Hello, how are you?", "conversation_id": null, "context": null}'
Test-Endpoint -TestName "Chat - Simple Query" -Method "POST" -Url "$apiUrl/chat" -Headers $chatHeaders -Body $chatBody -TimeoutSeconds 60

# Test 3: Chat Endpoint - AI Question
$aiChatBody = '{"query": "What is artificial intelligence?", "conversation_id": null, "context": null}'
Test-Endpoint -TestName "Chat - AI Question" -Method "POST" -Url "$apiUrl/chat" -Headers $chatHeaders -Body $aiChatBody -TimeoutSeconds 60

# Test 4: Chat Endpoint - Technical Query
$techChatBody = '{"query": "Explain machine learning", "conversation_id": null, "context": null}'
Test-Endpoint -TestName "Chat - Technical Query" -Method "POST" -Url "$apiUrl/chat" -Headers $chatHeaders -Body $techChatBody -TimeoutSeconds 60

# Test 5: Admin Indexing - Start Indexing
$adminHeaders = @{'Content-Type' = 'application/json'}
$indexBody = '{"data_type": "invoices", "options": null}'
Test-Endpoint -TestName "Admin - Start Indexing" -Method "POST" -Url "$apiUrl/admin/index" -Headers $adminHeaders -Body $indexBody -TimeoutSeconds 30

# Test 6: Test with Context
$contextChatBody = '{"query": "What can you tell me about invoices?", "conversation_id": null, "context": {"source": "business_data"}}'
Test-Endpoint -TestName "Chat - With Context" -Method "POST" -Url "$apiUrl/chat" -Headers $chatHeaders -Body $contextChatBody -TimeoutSeconds 60

# Test 7: Invalid Endpoint (should return 404)
Test-Endpoint -TestName "Invalid Endpoint" -Method "GET" -Url "$apiUrl/nonexistent" -ExpectedStatusCode 404

# Summary
Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Yellow
Write-Host "Total Tests: $testCount" -ForegroundColor White
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $($testCount - $passCount)" -ForegroundColor Red
Write-Host "Success Rate: $([math]::Round(($passCount / [math]::Max($testCount, 1)) * 100, 2))%" -ForegroundColor White

# Display detailed results
Write-Host "`n=== DETAILED RESULTS ===" -ForegroundColor Yellow
$results | Format-Table -AutoSize

# Save results to file
$results | Export-Csv -Path "rag_chatbot_test_results.csv" -NoTypeInformation
Write-Host "Results saved to: rag_chatbot_test_results.csv" -ForegroundColor Green