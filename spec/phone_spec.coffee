assert = require('chai').assert
fields = require('leadconduit-fields')
integration = require('../src/phone')
time = require('timekeeper')


describe 'Phone Request', ->

  beforeEach ->
    time.freeze(new Date('Thu, 10 Jul 2014 17:45:32 +0000'))
    process.env.TELESIGN_CUSTOMER_ID = 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE'
    process.env.TELESIGN_ENCODED_API_KEY = 'vW4G4ZmvGKby2dlowcdHxhkwy5RqwC+mfV9eVk3p'
    @vars = lead: { phone_1: '7732658399' }
    @request = integration.request(@vars)

  afterEach ->
    time.reset()

  it 'should have url', ->
    assert.equal @request.url, 'https://rest.telesign.com/v1/phoneid/live/17732658399?ucid=LEAD&x-ts-date=Thu%2C%2010%20Jul%202014%2017%3A45%3A32%20%2B0000&x-ts-authorization=TSA%20AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE%3AIqV%2FJHSu25rLtf4K4TxiD5Bt3RE%3D'

  it 'should be get', ->
    assert.equal 'GET', @request.method

  it 'should mask API key and customer ID on second invocation', ->
    request2 = integration.request(@vars)
    assert.equal request2.url, 'https://rest.telesign.com/v1/phoneid/live/17732658399?ucid=LEAD&x-ts-date=Thu%2C%2010%20Jul%202014%2017%3A45%3A32%20%2B0000&x-ts-authorization=TSA%20************************************%3AOATsQ9OCN%2F5AwWcsofH2G1HOsBw%3D'



describe 'Phone Response', ->
  # success is defined as a non-partial transaction with the subscriber status of 'Active'
  # and with a phone_type_code not equal to 6, 7, 8, 9, 11, or 20
  it 'should parse JSON body and return success when criteria matches', ->
    vars = {}
    req = {}
    res =
      status: 200,
      headers:
        'Content-Type': 'application/json'
      body: '
        {"reference_id": "0147216155F00D04E40012C600017C63", "resource_uri": null, "sub_resource": "live", "status": {"updated_on": "2014-07-10T17:45:33.140531Z", "code": 300, "description": "Transaction successfully completed"}, "errors": [], "phone_type": {"code": "1", "description": "FIXED_LINE"}, "live": {"subscriber_status": "ACTIVE", "device_status": "REACHABLE", "roaming": "UNAVAILABLE", "roaming_country": null, "roaming_country_iso2": null}, "location": {"city": "CHICAGO", "state": "IL", "zip": "60611", "metro_code": "1600", "county": "COOK", "country": {"name": "United States", "iso2": "US", "iso3": "USA"}, "coordinates": {"latitude": 41.87829, "longitude": -87.71248}, "time_zone": {"name": "America/Chicago", "utc_offset_min": "-6", "utc_offset_max": "-6"}}, "numbering": {"original": {"complete_phone_number": "17732658399", "country_code": "1", "phone_number": "7732658399"}, "cleansing": {"call": {"country_code": "1", "phone_number": "7732658399", "cleansed_code": 100, "min_length": 10, "max_length": 10}, "sms": {"country_code": "1", "phone_number": "7732658399", "cleansed_code": 100, "min_length": 10, "max_length": 10}}}, "carrier": {"name": "AT&T - PSTN"}}
      '
    expected =
      live:
        outcome: "success"
        billable: true
        errors: []
        phone_type: "Fixed line"
        risk: "low"
        carrier: "AT&T - PSTN"
        subscriber_status: "Active"
        device_status: "Reachable"
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

    response = integration.response(vars, req, res)
    assert.deepEqual response, expected

  it 'should parse JSON body and return failure when phone_type is 6, 7, 8, 9, 11, or 20', ->
    vars = {}
    req = {}
    res =
      status: 200,
      headers:
        'Content-Type': 'application/json'
      body: '
        {"reference_id": "0147216155F00D04E40012C600017C63", "resource_uri": null, "sub_resource": "live", "status": {"updated_on": "2014-07-10T17:45:33.140531Z", "code": 300, "description": "Transaction successfully completed"}, "errors": [], "phone_type": {"code": "6", "description": "PAGER"}, "live": {"subscriber_status": "ACTIVE", "device_status": "REACHABLE", "roaming": "UNAVAILABLE", "roaming_country": null, "roaming_country_iso2": null}, "location": {"city": "CHICAGO", "state": "IL", "zip": "60611", "metro_code": "1600", "county": "COOK", "country": {"name": "United States", "iso2": "US", "iso3": "USA"}, "coordinates": {"latitude": 41.87829, "longitude": -87.71248}, "time_zone": {"name": "America/Chicago", "utc_offset_min": "-6", "utc_offset_max": "-6"}}, "numbering": {"original": {"complete_phone_number": "17732658399", "country_code": "1", "phone_number": "7732658399"}, "cleansing": {"call": {"country_code": "1", "phone_number": "7732658399", "cleansed_code": 100, "min_length": 10, "max_length": 10}, "sms": {"country_code": "1", "phone_number": "7732658399", "cleansed_code": 100, "min_length": 10, "max_length": 10}}}, "carrier": {"name": "AT&T - PSTN"}}
      '
    expected =
      live:
        outcome: "failure"
        billable: true
        reason: 'Bad phone type'
        errors: []
        phone_type: "Pager"
        risk: "high"
        carrier: "AT&T - PSTN"
        subscriber_status: "Active"
        device_status: "Reachable"
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

    response = integration.response(vars, req, res)
    assert.deepEqual response, expected

  it 'should parse JSON body and return failure when subscriber status is Inactive', ->
    vars = {}
    req = {}
    res =
      status: 200,
      headers:
        'Content-Type': 'application/json'
      body: '
        {"reference_id": "0147216155F00D04E40012C600017C63", "resource_uri": null, "sub_resource": "live", "status": {"updated_on": "2014-07-10T17:45:33.140531Z", "code": 300, "description": "Transaction successfully completed"}, "errors": [], "phone_type": {"code": "2", "description": "MOBILE"}, "live": {"subscriber_status": "INACTIVE", "device_status": "REACHABLE", "roaming": "UNAVAILABLE", "roaming_country": null, "roaming_country_iso2": null}, "location": {"city": "CHICAGO", "state": "IL", "zip": "60611", "metro_code": "1600", "county": "COOK", "country": {"name": "United States", "iso2": "US", "iso3": "USA"}, "coordinates": {"latitude": 41.87829, "longitude": -87.71248}, "time_zone": {"name": "America/Chicago", "utc_offset_min": "-6", "utc_offset_max": "-6"}}, "numbering": {"original": {"complete_phone_number": "17732658399", "country_code": "1", "phone_number": "7732658399"}, "cleansing": {"call": {"country_code": "1", "phone_number": "7732658399", "cleansed_code": 100, "min_length": 10, "max_length": 10}, "sms": {"country_code": "1", "phone_number": "7732658399", "cleansed_code": 100, "min_length": 10, "max_length": 10}}}, "carrier": {"name": "AT&T - PSTN"}}
      '
    expected =
      live:
        outcome: "failure"
        reason: 'Subscriber inactive'
        billable: true
        errors: []
        phone_type: "Mobile"
        risk: "medium-low"
        carrier: "AT&T - PSTN"
        subscriber_status: "Inactive"
        device_status: "Reachable"
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

    response = integration.response(vars, req, res)
    assert.deepEqual response, expected

  it 'should parse JSON body and return failure + partial on status 301', ->
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
        outcome: "failure"
        billable: true
        reason: "Partial transaction"
        partial: true
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
        outcome: "failure"
        reason: "Partial transaction"
        billable: true
        partial: true
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

  it 'should correctly capitalize two-word locations', ->
    vars = {}
    req = {}
    res =
      status: 200,
      headers:
        'Content-Type': 'application/json'
      body: '
                  {"reference_id": "01466D0F94F30E02E400124900017E76", "resource_uri": null, "sub_resource": "live", "status": {"updated_on": "2014-06-05T17:24:36.587351Z", "code": 301, "description": "Transaction partially completed"}, "errors": [{"code": -60001, "description": "PhoneID Live Data Not Found"}], "phone_type": {"code": "2", "description": "MOBILE"}, "live": null, "location": {"city": "sIoUx FALLS", "state": "SOUTH dakota", "zip": null, "metro_code": null, "county": "FAll riVer", "country": {"name": "United States", "iso2": "US", "iso3": "USA"}, "coordinates": {"latitude": 37.34728, "longitude": -108.58756}, "time_zone": {"name": "America/Denver", "utc_offset_min": "-7", "utc_offset_max": "-7"}}, "numbering": {"original": {"complete_phone_number": "19707396346", "country_code": "1", "phone_number": "9707396346"}, "cleansing": {"call": {"country_code": "1", "phone_number": "9707396346", "cleansed_code": 100, "min_length": 10, "max_length": 10}, "sms": {"country_code": "1", "phone_number": "9707396346", "cleansed_code": 100, "min_length": 10, "max_length": 10}}}, "carrier": {"name": "Verizon Wireless"}}
                  '
    expected =
      live:
        outcome: "failure"
        reason: "Partial transaction"
        billable: true
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

    response = integration.response(vars, req, res)
    assert.equal 'Sioux Falls', response.live.location.city
    assert.equal 'Fall River', response.live.location.county

  it 'should correctly capitalize subscriber_status, device_status, roaming', ->
    vars = {}
    req = {}
    res =
      status: 200,
      headers:
        'Content-Type': 'application/json'
      body: '
        {"reference_id": "0147216155F00D04E40012C600017C63", "resource_uri": null, "sub_resource": 
        "live", "status": {"updated_on": "2014-07-10T17:45:33.140531Z", "code": 300, 
        "description": "Transaction successfully completed"}, "errors": [], 
        "phone_type": {"code": "1", "description": "FIXED_LINE"}, 
        "live": {"subscriber_status": "ACTIVE", "device_status": "REACHABLE",
        "roaming": "UNAVAILABLE", "roaming_country": null, "roaming_country_iso2": null}, 
        "location": {"city": "CHICAGO", "state": "IL", "zip": "60611", "metro_code": "1600", 
        "county": "COOK", "country": {"name": "United States", "iso2": "US", "iso3": "USA"}, 
        "coordinates": {"latitude": 41.87829, "longitude": -87.71248}, "time_zone": 
        {"name": "America/Chicago", "utc_offset_min": "-6", "utc_offset_max": "-6"}}, 
        "numbering": {"original": {"complete_phone_number": "17732658399", "country_code": "1", "phone_number": "7732658399"}, 
        "cleansing": {"call": {"country_code": "1", "phone_number": "7732658399", "cleansed_code": 100, 
        "min_length": 10, "max_length": 10}, "sms": {"country_code": "1", "phone_number": "7732658399", 
        "cleansed_code": 100, "min_length": 10, "max_length": 10}}}, "carrier": {"name": "AT&T - PSTN"}}
      '
    expected =
      live:
        outcome: "success"
        errors: []
        phone_type: "Fixed line"
        risk: "low"
        carrier: "AT&T - PSTN"
        subscriber_status: "Active"
        device_status: "Reachable"
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
        
    response = integration.response(vars, req, res)
    assert.equal 'Active', response.live.subscriber_status
    assert.equal 'Reachable', response.live.device_status
    assert.equal 'Unavailable', response.live.roaming


describe 'Validation', ->

  it 'should not allow null phone', ->
    error = integration.validate(lead: { phone_1: null })
    assert.equal error, 'phone must not be blank'

  it 'should not allow undefined phone', ->
    error = integration.validate(lead: {})
    assert.equal error, 'phone must not be blank'

  it 'should not allow invalid phone', ->
    error = integration.validate(lead: fields.buildLeadVars(phone_1: 'donkey'))
    assert.equal error, 'phone must be valid'

  it 'should not allow masked phone', ->
    error = integration.validate(lead: fields.buildLeadVars(phone_1: '(512) ***-****'))
    assert.equal error, 'phone must not be masked'

  it 'should not error when phone_1 is valid', ->
    error = integration.validate(lead: fields.buildLeadVars(phone_1: '5127891111'))
    assert.isUndefined error

  it 'should not error when phone_1 is missing the valid key', ->
    error = integration.validate(lead: { phone_1: '5127891111' })
    assert.isUndefined error



  
