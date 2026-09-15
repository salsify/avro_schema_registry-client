# frozen_string_literal: true

require 'logger'
require 'socket'
require 'timeout'

# Stands in for Rack::Timeout::RequestTimeoutException, which subclasses
# Exception rather than StandardError and is delivered via Thread#raise.
class SimulatedRequestTimeout < Exception; end # rubocop:disable Lint/InheritException

# A registry that keeps the connection open and can delay its first response for
# one subject, so interrupting that request leaves its response on the wire.
class KeepAliveRegistryServer
  IDS = { 'slow-subject' => 11, 'fast-subject' => 22 }.freeze

  attr_reader :port

  def initialize(slow_subject:, delay:)
    @slow_subject = slow_subject
    @delay = delay
    @server = TCPServer.new('127.0.0.1', 0)
    @port = @server.addr[1]
    @slow_response_written = false
  end

  def start
    @thread = Thread.new do
      loop do
        client = @server.accept
        Thread.new(client) { |socket| serve(socket) }
      end
    end
    self
  end

  def stop
    @thread&.kill
    @server.close
  end

  def url
    "http://127.0.0.1:#{@port}"
  end

  # Wait until the delayed response has been written, so the next request is
  # guaranteed to find it waiting in the socket.
  def wait_for_slow_response(timeout: 5)
    deadline = Time.now + timeout
    sleep(0.05) until @slow_response_written || Time.now > deadline
  end

  private

  def serve(socket)
    while (request_line = socket.gets)
      break if request_line.strip.empty?

      nil while (header = socket.gets) && !header.strip.empty?
      path = request_line.split(' ')[1]
      subject = IDS.keys.find { |name| path.include?(name) }

      if subject == @slow_subject && !@slow_response_written
        sleep(@delay)
        write_response(socket, subject)
        @slow_response_written = true
      else
        write_response(socket, subject)
      end
    end
  rescue StandardError
    nil
  ensure
    socket.close
  end

  # No Connection: close, and the socket is left open, as a keep-alive registry
  # behind a load balancer would leave it.
  def write_response(socket, subject)
    body = { id: IDS.fetch(subject, -1) }.to_json
    socket.write("HTTP/1.1 200 OK\r\n" \
                 "Content-Type: application/vnd.schemaregistry.v1+json\r\n" \
                 "Content-Length: #{body.bytesize}\r\n" \
                 "\r\n" \
                 "#{body}")
  end
end

describe AvroSchemaRegistry::Client do
  let(:logger) { Logger.new(StringIO.new) }
  let(:server) { KeepAliveRegistryServer.new(slow_subject: 'slow-subject', delay: 1).start }
  let(:registry) { described_class.new(server.url, logger: logger) }
  let(:schema) do
    { type: 'record', name: 'person', fields: [{ name: 'name', type: 'string' }] }.to_json
  end

  # WebMock intercepts inside the Excon adapter, so no socket is ever created
  # and the connection reuse this covers cannot happen through it.
  before { WebMock.disable! }

  after do
    WebMock.enable!
    server.stop
  end

  describe "#lookup_subject_schema" do
    context "when a previous request on the same thread was interrupted" do
      it "does not return the id from the interrupted request's response" do
        begin
          Timeout.timeout(0.25, SimulatedRequestTimeout) do
            registry.lookup_subject_schema('slow-subject', schema)
          end
          raise 'expected the lookup to be interrupted'
        rescue SimulatedRequestTimeout
          nil
        end
        server.wait_for_slow_response

        expect(registry.lookup_subject_schema('fast-subject', schema))
          .to eq(KeepAliveRegistryServer::IDS.fetch('fast-subject'))
      end
    end
  end
end
