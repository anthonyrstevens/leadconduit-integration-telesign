baseUrl = 'https://bpi.briteverify.com/emails.json'



#
# Request Function -------------------------------------------------------
#

request = (vars) ->
  {
    url: "#{baseUrl}?address=#{vars.email}&apikey=#{vars.apikey}",
    method: 'GET',
    headers: {
      Accepts: 'application/json'
    }
  }

request.variables = ->
  apikey: 
    type: 'string',
    required: true,
    description: 'BriteVerify API Key'
  email: 
    type: 'string',
    required: true,
    description: 'Email address'



#
# Response Function ------------------------------------------------------
#

response = (vars, req, res) ->
  if res.status == 200
    event = JSON.parse(res.body)
    event['outcome'] = 'success'
    event
  else
    { outcome: 'error', reason: "BriteVerify error (#{res.status})" }
    
response.variables = ->
  address: 
    type: 'string',
    description: 'the email that was passed'
  account: 
    type: 'string',
    description: 'the inbox or account parsed from the email'
  domain: 
    type: 'string',
    description: 'the domain parsed from the email'
  status: 
    type: 'string',
    description: 'the status of the given email address'
  error_code: 
    type: 'number',
    description: 'a code representation of error'
  error: 
    type: 'string',
    description: 'the error message if the email is invalid'
  disposable: 
    type: 'boolean',
    description: 'is the email a temporary or "disposable" email address?'
  role_address: 
    type: 'boolean',
    description: 'is the email aside for a function rather than a person (postmaster, sales, admin, info, etc)?'
  duration: 
    type: 'number',
    description: 'the time it took to process your request'



#
# Exports ----------------------------------------------------------------
#

module.exports = {
  type: 'outbound',
  request: request,
  response: response
}

