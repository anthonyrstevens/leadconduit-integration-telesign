assert = require('chai').assert
integration = require('../src/email')

describe 'Email Request', ->
  request = null

  beforeEach ->
    request = integration.request(email: 'foo@bar.com', apikey: '1234')

  it 'should have url', ->
    assert.equal 'https://bpi.briteverify.com/emails.json?address=foo@bar.com&apikey=1234', request.url

  it 'should be get', ->
    assert.equal 'GET', request.method

  it 'should accept JSON', ->
    assert.equal 'application/json', request.headers.Accepts


describe 'Email Response', ->
  it 'should parse JSON body', ->
    vars = {}
    req = {}
    res =
      status: 200,
      headers:
        'Content-Type': 'application/json'
      body: """
            {
            "address":"james@yahoo.com",
            "account":"james",
            "domain":"yahoo.com",
            "status":"invalid",
            "error_code":"email_account_invalid",
            "error":"Email account invalid",
            "disposable":false,
            "role_address":false,
            "duration":0.141539548
            }
            """
    expected =
      outcome: 'success'
      address: "james@yahoo.com"
      account: "james"
      domain: "yahoo.com"
      status: "invalid"
      error_code: "email_account_invalid"
      error: "Email account invalid"
      disposable: false
      role_address: false
      duration: 0.141539548
    response = integration.response(vars, req, res)
    assert.deepEqual expected, response

  it 'should return error outcome on non-200 response status', ->
    vars = {}
    req = {}
    res =
      status: 400,
      headers:
        'Content-Type': 'application/json'
      body: """
            {
            "outcome":"error",
            "reason":"BriteVerify error (400)"
            }
            """
    expected =
      outcome: 'error'
      reason: 'BriteVerify error (400)'
    response = integration.response(vars, req, res)
    assert.deepEqual expected, response