# RAG Chatbot Docker Container Test
# Focused test for the RAG chatbot service running in Docker

$ragUrl = "http://localhost:8001"
$apiUrl = "$ragUrl/api/v1"

Write-Host "Testing RAG Chatbot Docker Container" -ForegroundColor Green
Write-Host "Container URL: $ragUrl" -ForegroundColor Gray
Write-Host "=" * 50

$testResults = @()

function Test-RAGEndpoint {
    param(
        [string]$TestName,
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers = @{},
        [string]$Body = $null,
        [int]$TimeoutSeconds = 120
    )
    
    Write-Host "`n[$TestName]" -ForegroundColor Cyan
    Write-Host "$Method $Url" -ForegroundColor Gray
    
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
        }
        
        $startTime = Get-Date
        $response = Invoke-WebRequest @params
        $duration = ((Get-Date) - $startTime).TotalSeconds
        
        $success = $response.StatusCode -eq 200
        $responseData = $null
        
        try {
            $responseData = $response.Content | ConvertFrom-Json
        } catch {
            $responseData = $response.Content
        }
        
        if ($success) {
            Write-Host "SUCCESS ($($response.StatusCode)) - ${duration}s" -ForegroundColor Green
            if ($responseData -and $responseData.GetType().Name -ne "String") {
                Write-Host "Response keys: $($responseData.PSObject.Properties.Name -join ', ')" -ForegroundColor Gray
            }
        } else {
            Write-Host "FAILED ($($response.StatusCode))" -ForegroundColor Red
        }
        
        $script:testResults += [PSCustomObject]@{
            Test = $TestName
            Success = $success
            StatusCode = $response.StatusCode
            Duration = "${duration}s"
            ResponseSize = $response.Content.Length
        }
        
        return $responseData
        
    } catch {
        $duration = ((Get-Date) - $startTime).TotalSeconds
        Write-Host "ERROR - $($_.Exception.Message)" -ForegroundColor Red
        
        $script:testResults += [PSCustomObject]@{
            Test = $TestName
            Success = $false
            StatusCode = "Error"
            Duration = "${duration}s"
            ResponseSize = 0
        }
        
        return $null
    }
}

# Test 1: Health Check
$healthResult = Test-RAGEndpoint -TestName "Health Check" -Method "GET" -Url "$ragUrl/health"

# Test 2: Basic Chat
Write-Host "`nTesting basic chat functionality..." -ForegroundColor Yellow

$chatHeaders = @{"Content-Type" = "application/json"}
$chatBody = @{
    query = "Hello, can you introduce yourself?"
    conversation_id = $null
    context = $null
} | ConvertTo-Json

$chatResult = Test-RAGEndpoint -TestName "Basic Chat" -Method "POST" -Url "$apiUrl/chat" -Headers $chatHeaders -Body $chatBody -TimeoutSeconds 180

if ($chatResult) {
    Write-Host "Chat Response Preview: $($chatResult.response.Substring(0, [Math]::Min(100, $chatResult.response.Length)))..." -ForegroundColor Gray
    $conversationId = $chatResult.conversation_id
    
    if ($conversationId) {
        Write-Host "Conversation ID: $conversationId" -ForegroundColor Gray
        
        # Test 3: Follow-up Chat
        $followupBody = @{
            query = "What can you help me with?"
            conversation_id = $conversationId
            context = $null
        } | ConvertTo-Json
        
        $followupResult = Test-RAGEndpoint -TestName "Follow-up Chat" -Method "POST" -Url "$apiUrl/chat" -Headers $chatHeaders -Body $followupBody -TimeoutSeconds 180
        
        if ($followupResult) {
            Write-Host "Follow-up Response Preview: $($followupResult.response.Substring(0, [Math]::Min(100, $followupResult.response.Length)))..." -ForegroundColor Gray
        }
        
        # Test 4: Conversation History
        $historyResult = Test-RAGEndpoint -TestName "Conversation History" -Method "GET" -Url "$apiUrl/conversations/$conversationId"
        
        if ($historyResult -and $historyResult.messages) {
            Write-Host "Conversation has $($historyResult.messages.Count) messages" -ForegroundColor Gray
        }
    }
}

# Test 5: Business Domain Chat
Write-Host "`nTesting business domain functionality..." -ForegroundColor Yellow

$businessBody = @{
    query = "How does invoice processing work?"
    conversation_id = $null
    context = @{
        domain = "business"
        type = "invoice"
    }
} | ConvertTo-Json

$businessResult = Test-RAGEndpoint -TestName "Business Domain Chat" -Method "POST" -Url "$apiUrl/chat" -Headers $chatHeaders -Body $businessBody -TimeoutSeconds 180

if ($businessResult) {
    Write-Host "Business Response Preview: $($businessResult.response.Substring(0, [Math]::Min(100, $businessResult.response.Length)))..." -ForegroundColor Gray
}

# Test 6: Admin Indexing (if available)
Write-Host "`nTesting admin functionality..." -ForegroundColor Yellow

$indexBody = @{
    data_type = "test_documents"
    options = @{
        full_refresh = $false
        batch_size = 5
    }
} | ConvertTo-Json

$indexResult = Test-RAGEndpoint -TestName "Data Indexing" -Method "POST" -Url "$apiUrl/admin/index" -Headers $chatHeaders -Body $indexBody -TimeoutSeconds 60

if ($indexResult -and $indexResult.task_id) {
    Write-Host "Indexing task started: $($indexResult.task_id)" -ForegroundColor Gray
    
    # Check indexing status
    Start-Sleep -Seconds 3
    $statusResult = Test-RAGEndpoint -TestName "Indexing Status" -Method "GET" -Url "$apiUrl/admin/index/status/$($indexResult.task_id)"
    
    if ($statusResult) {
        Write-Host "Indexing status: $($statusResult.status)" -ForegroundColor Gray
    }
}

# Test 7: Error Handling
Write-Host "`nTesting error handling..." -ForegroundColor Yellow

$emptyBody = @{
    query = ""
    conversation_id = $null
    context = $null
} | ConvertTo-Json

try {
    $errorResponse = Invoke-WebRequest -Uri "$apiUrl/chat" -Method POST -Headers $chatHeaders -Body $emptyBody -TimeoutSec 30
    Write-Host "[Empty Query Test] Unexpected success: $($errorResponse.StatusCode)" -ForegroundColor Yellow
} catch {
    if ($_.Exception.Response.StatusCode -eq 422) {
        Write-Host "[Empty Query Test] SUCCESS - Correctly rejected empty query (422)" -ForegroundColor Green
        $script:testResults += [PSCustomObject]@{
            Test = "Empty Query Validation"
            Success = $true
            StatusCode = 422
            Duration = "Quick"
            ResponseSize = 0
        }
    } else {
        Write-Host "[Empty Query Test] FAILED - Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
        $script:testResults += [PSCustomObject]@{
            Test = "Empty Query Validation"
            Success = $false
            StatusCode = "Error"
            Duration = "Quick"
            ResponseSize = 0
        }
    }
}

# Summary
Write-Host "`n" + "=" * 50 -ForegroundColor Green
Write-Host "TEST SUMMARY" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Green

$successCount = ($testResults | Where-Object { $_.Success -eq $true }).Count
$totalCount = $testResults.Count
$successRate = if ($totalCount -gt 0) { [math]::Round(($successCount / $totalCount) * 100, 1) } else { 0 }

Write-Host "Total Tests: $totalCount" -ForegroundColor White
Write-Host "Successful: $successCount" -ForegroundColor Green
Write-Host "Failed: $($totalCount - $successCount)" -ForegroundColor Red
Write-Host "Success Rate: $successRate%" -ForegroundColor White

Write-Host "`nDetailed Results:" -ForegroundColor Yellow
$testResults | Format-Table -Property Test, Success, StatusCode, Duration, ResponseSize -AutoSize

# Export results
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$resultsFile = "rag_container_test_$timestamp.csv"
$testResults | Export-Csv -Path $resultsFile -NoTypeInformation

Write-Host "`nResults exported to: $resultsFile" -ForegroundColor Cyan

if ($successRate -ge 80) {
    Write-Host "`nRAG CHATBOT CONTAINER: OPERATIONAL" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nRAG CHATBOT CONTAINER: NEEDS ATTENTION" -ForegroundColor Yellow
    exit 1
}