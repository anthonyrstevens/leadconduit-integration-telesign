assert = require('chai').assert
integration = require('../src/phone')
tk = require('timekeeper')

describe 'Phone Request', ->
  request = null

  beforeEach ->
    process.env.TELESIGN_ENCODED_API_KEY = 'vW4G4ZmvGKby2dlowcdHxhkwy5RqwC+mfV9eVk3p'
    d = new Date('Thu, 10 Jul 2014 17:45:32 +0000')
    tk.freeze(d)
    request = integration.request(lead: { phone_1: '7732658399' }, telesign: { customer_id: 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE' })
    tk.reset(d)

  it 'should have url', ->
    assert.equal request.url, 'https://rest.telesign.com/v1/phoneid/live/17732658399?ucid=LEAD&x-ts-date=Thu%2C%2010%20Jul%202014%2017%3A45%3A32%20%2B0000&x-ts-authorization=TSA%20AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE%3AIqV%2FJHSu25rLtf4K4TxiD5Bt3RE%3D'
  it 'should be get', ->
    assert.equal 'GET', request.method

describe 'Phone Response', ->
  it 'should parse JSON body and return success on status 300', ->
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
      live:
        outcome: "success"
        reference_id: "0147216155F00D04E40012C600017C63"
        errors: []
        phone_type: "Fixed line"
        risk: "low"
        carrier: "AT&T - PSTN"
        subscriber_status: "Active"
        device_status: "Unavailable"
        roaming: "Unavailable"
        roaming_country_code: null
        location:
          latitude: 41.87829
          longitude: -87.71248
          city: "Chicago"
          state: "IL"
          postal_code: "60611"
          metro_code: "1600"
          county: "Cook"
          country_code: "US"
          time_zone: "America/Chicago"
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
    response = integration.response(vars, req, res)
    assert.deepEqual response, expected

  it 'should parse JSON body and return partial success on status 301', ->
    vars = {}
    req = {}
    res =
      status: 200,
      headers:
        'Content-Type': 'application/json'
      body: '
            {"reference_id": "01466D0F94F30E02E400124900017E76", "resource_uri": null, "sub_resource": "live", "status": {"updated_on": "2014-06-05T17:24:36.587351Z", "code": 301, "description": "Transaction partially completed"}, "errors": [{"code": -60001, "description": "PhoneID Live Data Not Found"}], "phone_type": {"code": "2", "description": "MOBILE"}, "live": null, "location": {"city": "Cortez", "state": "CO", "zip": "81321", "metro_code": "", "county": "Montezuma", "country": {"name": "United States", "iso2": "US", "iso3": "USA"}, "coordinates": {"latitude": 37.34728, "longitude": -108.58756}, "time_zone": {"name": "America/Denver", "utc_offset_min": "-7", "utc_offset_max": "-7"}}, "numbering": {"original": {"complete_phone_number": "19707396346", "country_code": "1", "phone_number": "9707396346"}, "cleansing": {"call": {"country_code": "1", "phone_number": "9707396346", "cleansed_code": 100, "min_length": 10, "max_length": 10}, "sms": {"country_code": "1", "phone_number": "9707396346", "cleansed_code": 100, "min_length": 10, "max_length": 10}}}, "carrier": {"name": "Verizon Wireless"}}
            '
    expected =
      live:
        outcome: "success"
        partial: true
        reference_id: "01466D0F94F30E02E400124900017E76"
        errors: [
          code: -60001
          description: "PhoneID Live Data Not Found"
        ]
        phone_type: "Mobile"
        risk: "medium-low"
        carrier: "Verizon Wireless"
        subscriber_status: null
        device_status: null
        roaming: null
        roaming_country_code: null
        location:
          latitude: 37.34728
          longitude: -108.58756
          city: "Cortez"
          state: "CO"
          postal_code: "81321"
          metro_code: ""
          county: "Montezuma"
          country_code: "US"
          time_zone: "America/Denver"
        numbering:
          original:
            complete_phone_number: "19707396346"
            country_code: "1"
            phone_number: "9707396346"
          cleansing:
            call:
              country_code: "1"
              phone_number: "9707396346"
              cleansed_code: 100
              min_length: 10
              max_length: 10
            sms:
              country_code: "1"
              phone_number: "9707396346"
              cleansed_code: 100
              min_length: 10
              max_length: 10
    response = integration.response(vars, req, res)
    assert.deepEqual response, expected

  it 'should correctly parse null values for live and location', ->
    vars = {}
    req = {}
    res =
      status: 200,
      headers:
        'Content-Type': 'application/json'
      body: '
                  {"reference_id": "01466D0F94F30E02E400124900017E76", "resource_uri": null, "sub_resource": "live", "status": {"updated_on": "2014-06-05T17:24:36.587351Z", "code": 301, "description": "Transaction partially completed"}, "errors": [{"code": -60001, "description": "PhoneID Live Data Not Found"}], "phone_type": {"code": "2", "description": "MOBILE"}, "live": null, "location": {"city": null, "state": null, "zip": null, "metro_code": null, "county": null, "country": {"name": "United States", "iso2": "US", "iso3": "USA"}, "coordinates": {"latitude": 37.34728, "longitude": -108.58756}, "time_zone": {"name": "America/Denver", "utc_offset_min": "-7", "utc_offset_max": "-7"}}, "numbering": {"original": {"complete_phone_number": "19707396346", "country_code": "1", "phone_number": "9707396346"}, "cleansing": {"call": {"country_code": "1", "phone_number": "9707396346", "cleansed_code": 100, "min_length": 10, "max_length": 10}, "sms": {"country_code": "1", "phone_number": "9707396346", "cleansed_code": 100, "min_length": 10, "max_length": 10}}}, "carrier": {"name": "Verizon Wireless"}}
                  '
    expected =
      live:
        outcome: "success"
        partial: true
        reference_id: "01466D0F94F30E02E400124900017E76"
        errors: [
          code: -60001
          description: "PhoneID Live Data Not Found"
        ]
        phone_type: "Mobile"
        risk: "medium-low"
        carrier: "Verizon Wireless"
        subscriber_status: null
        device_status: null
        roaming: null
        roaming_country_code: null
        location:
          latitude: 37.34728
          longitude: -108.58756
          city: null
          state: null
          postal_code: null
          metro_code: null
          county: null
          country_code: "US"
          time_zone: "America/Denver"
        numbering:
          original:
            complete_phone_number: "19707396346"
            country_code: "1"
            phone_number: "9707396346"
          cleansing:
            call:
              country_code: "1"
              phone_number: "9707396346"
              cleansed_code: 100
              min_length: 10
              max_length: 10
            sms:
              country_code: "1"
              phone_number: "9707396346"
              cleansed_code: 100
              min_length: 10
              max_length: 10
    response = integration.response(vars, req, res)
    assert.deepEqual response, expected

  it 'should parse JSON body and return error on status 501', ->
    vars = {}
    req = {}
    res =
      status: 200,
      headers:
        'Content-Type': 'application/json'
      body: """
             {"status": {"updated_on": "2014-05-15T18:33:15.588855Z", "code": 501, "description": "Not authorized"}, "signature_string": "GET\\n\\n\\nx-ts-date:Thu, 15 May 2014 18:33:15 +0000\\n/v1/phoneid/live/16503936308", "errors": [{"code": -30006, "description": "Invalid Signature."}]}
          """
    expected =
      live:
        outcome: "error"
        errors: [
          code: -30006
          description: "Invalid Signature."
        ]
    response = integration.response(vars, req, res)
    assert.deepEqual response, expected

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
            "reason":"TeleSign error (400)"
            }
            """
    expected =
      live:
        outcome: 'error'
        reason: 'TeleSign error (400)'
    response = integration.response(vars, req, res)
    assert.deepEqual response, expected