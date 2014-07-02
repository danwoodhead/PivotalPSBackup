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

function GetUrl {
  param($projectId,$limit,$offset)
  # by default in v5 you don't get tasks or comments
  # also only first 100, max limit is 500...
  Return "https://www.pivotaltracker.com/services/v5/projects/$projectId/stories/?fields=name,estimate,description,story_type,created_at,current_state,accepted_at,url,labels(name),tasks(description,complete),comments(text)&limit=$limit&envelope=true&offset=$offset"
}

$apiToken = GetPivotalToken
$dateStamp = get-date -f yyyyMMddTHHmmss    # only used once
$rootPath = "D:\danny boy\backup\pivotal"   # only used once
$limit = 500 # max the api will return, rename to upper limit
$projects =  GetPivotalProjects

foreach ($projectId in $projects.Keys) {
  $offset = 0

  <# call a function to get the total stories
  $remaining = $total
  $stories = [] # ?? needed for scope??

  while ($remaining -gt 0) {
    # limit just a local variable here
    if ($remaining -lt $upperlimit) then $limit = $remaining else $limit = $upperlimit
    $stories = $stories + (curl -k -H "X-TrackerToken: $apiToken" -X GET (GetUrl $projectId $limit $offset))
    $offset = $offset + $limit
    $remaining = $remaining - $limit
  }
  #>

  $stories = curl -k -H "X-TrackerToken: $apiToken" -X GET (GetUrl $projectId $limit $offset)
  $storiesAsJson = $ser.DeserializeObject($stories)
  $total = $storiesAsJson.pagination.total
  $remaining = $total - $limit

  # so, if < 500 stories then do once
  # if > 500 then call again, offset 500 or 501 (test)
  while ($remaining -gt 0) {
    # offset for querystring
    $offset = $offset + $limit # so 500, 1000 etc.  might change to 501, 1001 etc if get dupes

    $stories = $stories + (curl -k -H "X-TrackerToken: $apiToken" -X GET (GetUrl $projectId $limit $offset))

    # decrement by limit
    $remaining = $remaining - $limit
  }

  $stories > "$rootPath\$($projects.Item($projectId)).$dateStamp.json"
}