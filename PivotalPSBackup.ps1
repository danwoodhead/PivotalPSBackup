[System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer

function GetPivotalToken {
  # text file containing your token
  Return Get-Content .\token.txt 
}

function GetPivotalProjects {
  # from http://stackoverflow.com/questions/10743892/loading-a-powershell-hashtable-from-a-file
  # powershell hashtable of project ids and a chosen names e.g. @{1234567 = "project1"; 7654321 = "project2"}
  Return  gc .\projects.pson | Out-String | iex
  #Return @{1012782 = "my_work"}
}

$apiToken = GetPivotalToken
$dateStamp = get-date -f yyyyMMddTHHmmss
$rootPath = "D:\danny boy\backup\pivotal"
$limit = 500
$projects =  GetPivotalProjects

# by default in v5 you don't get tasks or comments
# also only first 100, max limit is 500...
# &filter= from https://www.pivotaltracker.com/help/faq#howcanasearchberefined
$queryString = "/stories/?fields=name,estimate,description,story_type,created_at,current_state,accepted_at,url,labels(name),tasks(description,complete),comments(text)&limit=$limit&envelope=true"


foreach ($projectId in $projects.Keys) {
  $output = "$rootPath\$($projects.Item($projectId)).$dateStamp.json"

  $stories = curl -k -H "X-TrackerToken: $apiToken" -X GET https://www.pivotaltracker.com/services/v5/projects/$projectId$queryString
  $storiesAsJson = $ser.DeserializeObject($stories)
  $total = $storiesAsJson.pagination.total
  $offset = $storiesAsJson.pagination.offset
  $remaining = $total - $limit

  # so, if < 500 stories then do once
  # if > 500 then call again, offset 500 or 501 (test)
  while ($remaining -gt 0) {
    # offset for querystring
    $offset = $offset + $limit # so 500, 1000 etc.  might change to 501, 1001 etc if get dupes
    
    #todo do in one line
    $offsetQueryString = "&offset=$offset"
    $temp = curl -k -H "X-TrackerToken: $apiToken" -X GET https://www.pivotaltracker.com/services/v5/projects/$projectId$queryString$offsetQueryString
    $stories = $stories + $temp

    # decrement by limit
    $remaining = $remaining - $limit
  }

  $stories > $output
}