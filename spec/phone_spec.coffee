assert = require('chai').assert
integration = require('../src/phone')

describe 'Phone Request', ->
  request = null

  beforeEach ->
    request = integration.request(lead: { phone1: '7732658399' }, telesign: { encoded_apikey: 'vW4G4ZmvGKby2dlowcdHxhkwy5RqwC+mfV9eVk3p', customer_id: 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE' })

  it 'should have url', ->
    assert.include request.url, 'https://rest.telesign.com/v1/phoneid/live/17732658399?ucid=LEAD&signature=TSA AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE'

  it 'should be get', ->
    assert.equal 'GET', request.method

describe 'Email Response', ->
  it 'should parse JSON body', ->
    vars = {}
    req = {}
    res =
      status: 200,
      headers:
        'Content-Type': 'application/json'
      body: '
        {"reference_id": "0147216155F00D04E40012C600017C63", "resource_uri": null, "sub_resource": "live", "status": {"updated_on": "2014-07-10T17:45:33.140531Z", "code": 300, "description": "Transaction successfully completed"}, "errors": [], "phone_type": {"code": "1", "description": "FIXED_LINE"}, "live": {"subscriber_status": "ACTIVE", "device_status": "UNAVAILABLE", "roaming": "UNAVAILABLE", "roaming_country": null, "roaming_country_iso2": null}, "location": {"city": "CHICAGO", "state": "IL", "zip": "60611", "metro_code": "1600", "county": "COOK", "country": {"name": "United States", "iso2": "US", "iso3": "USA"}, "coordinates": {"latitude": 41.87829, "longitude": -87.71248}, "time_zone": {"name": "America/Chicago", "utc_offset_min": "-6", "utc_offset_max": "-6"}}, "numbering": {"original": {"complete_phone_number": "17732658399", "country_code": "1", "phone_number": "7732658399"}, "cleansing": {"call": {"country_code": "1", "phone_number": "7732658399", "cleansed_code": 100, "min_length": 10, "max_length": 10}, "sms": {"country_code": "1", "phone_number": "7732658399", "cleansed_code": 100, "min_length": 10, "max_length": 10}}}, "carrier": {"name": "AT&T - PSTN"}}
      '
    expected =
      telesign:
        phone:
          outcome: 'success'
          reference_id: "0147216155F00D04E40012C600017C63"
          resource_uri: null
          sub_resource: "live"
          status:
            updated_on: "2014-07-10T17:45:33.140531Z"
            code: 300
            description: "Transaction successfully completed"
          errors: []
          phone_type:
            code: "1"
            description: "FIXED_LINE"
          live:
            subscriber_status: "ACTIVE"
            device_status: "UNAVAILABLE"
            roaming: "UNAVAILABLE"
            roaming_country: null
            roaming_country_iso2: null
          location:
            city: "CHICAGO"
            state: "IL"
            zip: "60611"
            metro_code: "1600"
            county: "COOK"
            country:
              name: "United States"
              iso2: "US"
              iso3: "USA"
            coordinates:
              latitude: 41.87829
              longitude: -87.71248
            time_zone:
              name: "America/Chicago"
              utc_offset_min: "-6"
              utc_offset_max: "-6"
          numbering:
            original:
              complete_phone_number: "17732658399"
              country_code: "1"
              phone_number: "7732658399"
            cleansing:
              call:
                country_code: "1"
                phone_number: "7732658399"
                cleansed_code: 100
                min_length: 10
                max_length: 10
              sms:
                country_code: "1"
                phone_number: "7732658399"
                cleansed_code: 100
                min_length: 10
                max_length: 10
          carrier:
            name: "AT&T - PSTN"
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
            "reason":"Telesign error (400)"
            }
            """
    expected =
      telesign:
        phone:
          outcome: 'error'
          reason: 'Telesign error (400)'
    response = integration.response(vars, req, res)
    assert.deepEqual expected, response