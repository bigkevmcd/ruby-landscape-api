require 'spec_helper'

describe Landscape do
  before (:each) do
    Timecop.travel(Time.local(2012, 9, 14, 18, 12, 12))
  end
  describe '.canonical_string' do
    it 'should generate the canonical_string in the format Landscape expects' do
      uri = URI('https://landscape.canonical.com/api/')
      params = {name1: 'value1', name2: 'value2 has spaces', name3: 'value3~'}
      Landscape.canonical_string(params, uri).should == "POST\nlandscape.canonical.com\n/api/\nname1=value1&name2=value2%20has%20spaces&name3=value3~"
    end
  end

  describe '.pathlist' do
    it 'should convert a single element array into a numbered, keyed hash' do
      Landscape.pathlist('tags', ['web']).should == {'tags.1'=>'web'}
    end
    it 'should convert a multi element array into a numbered, keyed hash' do
      Landscape.pathlist('tags', ['web', 'server']).should == {'tags.1'=>'web', 'tags.2'=>'server'}
    end
  end

  describe Landscape::Client do
    let (:landscape) { Landscape::Client.new(api_access_key: 'not a key', secret_access_key: 'not a secret')}
    it 'should default to https://landscape.canonical.com for the endpoint' do
      landscape.endpoint.should == 'https://landscape.canonical.com/api/'
    end

    it 'should be possible to specify an endpoint' do
      client = Landscape::Client.new(api_access_key: 'not a key',
                                     secret_access_key: 'not a secret',
                                     endpoint: 'https://example.com/api/')
      client.endpoint.should == 'https://example.com/api/'
    end

    it 'should raise an error if no api_access_key is supplied' do
      expect { Landscape::Client.new(api_access_key: 'not a key') }.to raise_error(ArgumentError)
    end
    it 'should raise an error if no secret_access_key is supplied' do
      expect { Landscape::Client.new(secret_access_key: 'a secret key') }.to raise_error(ArgumentError)
    end

    context '#make_request' do
      it 'should call the remote server with our parameters' do
        stub_request(:post, 'https://landscape.canonical.com/api/').
          with(:body => {'access_key_id'=>'not a key',
                        'action'=>'GetComputers',
                        'signature'=>'lBTA+RRW1zf4HDEZpMY88h8viNdN2rSupTxPicyqSuc=',
                        'signature_method'=>'HmacSHA256',
                        'signature_version'=>'2',
                        'timestamp'=>'2012-09-14T17:12:12Z',
                        'version'=>'2011-08-01'},
              :headers => {'Accept'=>'*/*', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'landscape-api-ruby-gem'}).
          to_return(:status => 200, :body => '', :headers => {'content-type' => ['application/json']})
        landscape.make_request('GetComputers', {})
      end
    end
    context '#fetch_response' do
      it 'should call the remote server with our parameters' do
        stub_request(:post, 'https://landscape.canonical.com/api/').
          with(:body => {'access_key_id'=>'not a key',
                         'action'=>'GetComputers',
                         'signature'=>'NQmtWOtLQTqawygcrD9sDP24s3KVOASLOUVn0tumdkE=',
                         'signature_method'=>'HmacSHA256',
                         'signature_version'=>'2',
                         'tags.1'=>'web',
                         'tags.2'=>'server',
                         'timestamp'=>'2012-09-14T17:12:12Z',
                         'version'=>'2011-08-01'},
               :headers => {'Accept'=>'*/*', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'landscape-api-ruby-gem'}).
          to_return(:status => 201, :body => [], :headers => {})
        landscape.fetch_response(action: 'GetComputers', params: Landscape.pathlist('tags', ['web', 'server'])).should == []
      end
    end
  end
end
