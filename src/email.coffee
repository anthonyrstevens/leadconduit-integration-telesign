baseUrl = 'https://bpi.briteverify.com/emails.json'

request = (vars) ->
  {
    url: "#{baseUrl}?address=#{vars.email}&apikey=#{vars.apikey}",
    method: 'GET',
    headers: {
      Accepts: 'application/json'
    }
  }

response = (vars, req, res) ->
  if res.status == 200
    event = JSON.parse(res.body)
    event['outcome'] = 'success'
    event
  else
    { outcome: 'error', reason: "BriteVerify error (#{res.status})" }

module.exports = {
  request: request,
  response: response
}

