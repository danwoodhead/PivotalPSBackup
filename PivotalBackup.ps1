[System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer



$apiToken = Get-Content .\token.txt # text file containing your token
$dateStamp = get-date -f yyyyMMddTHHmmss
$rootPath = "D:\danny boy\backup\pivotal"
$limit = 500

# from http://stackoverflow.com/questions/10743892/loading-a-powershell-hashtable-from-a-file
# powershell hashtable of project ids and a chosen names
# @{1234567 = "project1"; 7654321 = "project2"}
# @{1012782 = "my_work"; 1015186 = "home"; 1023974 = "unified"}
$projects =  gc .\projects.pson | Out-String | iex

# by default in v5 you don't get tasks or comments
# also only first 100, max limit is 500...
# &filter= from https://www.pivotaltracker.com/help/faq#howcanasearchberefined
# X-Tracker-Pagination-Total
$queryString = "/stories/?fields=name,estimate,description,story_type,created_at,current_state,accepted_at,url,labels(name),tasks(description,complete),comments(text)&limit=$limit&envelope=true"


 # curl -k -H "X-TrackerToken: ${JTOKEN}" -X GET 
foreach ($projectId in $projects.Keys) {
  $output = "$rootPath\$($projects.Item($projectId)).$dateStamp.json"
  curl -k -H "X-TrackerToken: $apiToken" -X GET https://www.pivotaltracker.com/services/v5/projects/$projectId$queryString > $output

  #$headers = curl -I -k -H "X-TrackerToken: $apiToken" -X GET https://www.pivotaltracker.com/services/v5/projects/$projectId/stories
  #$headersJson = $ser.DeserializeObject($headers)
  #Write-Output $headersJson

#  $stories = curl -k -H "X-TrackerToken: $apiToken" -X GET https://www.pivotaltracker.com/services/v5/projects/$projectId$queryString #> $output
#  $storiesAsJson = $ser.DeserializeObject($stories)
 # $total = $storiesAsJson.pagination.total
  #$offset = $storiesAsJson.pagination.offset
  #Write-Output $total


  # so, if < 500 the do once
  # if > 500 then call again, no envelope, offset 501
 # $remaining = $total - $limit
  #Write-Output "Offset $offset and remaining $remaining"
 # $queryString = $queryString + "&offset=$offset"
 # while ($remaining -gt 0) {
 #   $offset = $offset + $limit # so 500, 1000 etc
    #curl with no envelope, but limit and offset set.  append to output
 #   $temp = curl -k -H "X-TrackerToken: $apiToken" -X GET https://www.pivotaltracker.com/services/v5/projects/$projectId$queryString
 #   $remaining = $remaining - $limit
    #Write-Output "Offset $offset and remaining $remaining"
 #   $stories = $stories + $temp
 # }

#  $stories > $output
}