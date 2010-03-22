#!/usr/bin/env ruby

require 'rubygems'
require 'socket'
require 'openssl'
require "base64"
gem 'json_pure'
require 'json'

class TwitterPush

  def msg(fail,  msg) 
    [(fail ? 403 : 200), { 'Content-Type' => 'text/plain' }, msg ]
  end

  def call(env)
    req = Rack::Request.new(env)

    p = req.POST
    g = req.GET
   
    unless p.has_key?("X-Twitteremailtype")
      return msg(true, "ERROR: INVALID REQUEST; No X-Twitteremailtype")
    end
    unless p.has_key?("X-Twittersendername") 
      return msg(true, "ERROR: INVALID REQUEST; No X-Twittersendername")
    end
    unless p.has_key?("X-Twittersenderscreenname") 
      return msg(true, "ERROR: INVALID REQUEST; X-Twittersenderscreenname")
    end
    unless p.has_key?("plain")
      return msg(true, "ERROR: INVALID REQUEST; plain")
    end
    unless g.has_key?("device-id") 
      return msg(true, "ERROR: INVALID REQUEST; device-id")
    end
    unless g.has_key?("auth") 
      return msg(true, "ERROR: INVALID REQUEST; auth")
    end

    # check the auth
    left = Base64.encode64(g['device-id'].to_s[0,17]).strip
    right = (g['auth']).to_s.strip
    unless(left == right)
      return  msg(true, "ERROR: DEVICE ID NOT AUTHENTICATED: " + left + "|" + right)
    end

    msg = "Unknown twitter email"
    if(p['X-Twitteremailtype'] == 'direct_message')
      delim = p['X-Twittersendername'] + " / " + p['X-Twittersenderscreenname']
      guess_at_msg = p['plain'].split(delim)
      msg = "DM from " +  p['X-Twittersendername'] + ": " + guess_at_msg[0].to_s.strip
    end
    alert = {"action-loc-key" => "REPLY", :body => msg}
    message = JSON.generate({:aps => {:alert => alert, :sound => "chimes"}})

    key = [g['device-id'].to_s.delete(' ')].pack('H*')
    notification_packet = [0, 0, 32, key, 0, message.size, message].pack("ccca*cca*")

    clean_up_ssl if (@ssl and  @ssl.eof?) or (@sock and @sock.eof?)
    build_up_ssl if @ssl.nil? or @socket.nil? 

    begin
      @ssl.write(notification_packet)
    rescue
      clean_up_ssl
      build_up_ssl 
      @ssl.write(notification_packet)
    end
    msg false, 'OK'
  end
  
  def build_up_ssl
    context = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(File.read("push-cert.pem"))
    context.key = OpenSSL::PKey::RSA.new(File.read('push-cert.pem'))
    @sock = TCPSocket.new('gateway.sandbox.push.apple.com', 2195)
    @ssl = OpenSSL::SSL::SSLSocket.new(@sock,context)
    @ssl.connect
  end

  def clean_up_ssl
    @ssl.close
    @sock.close
    @ssl = nil
    @sock = nil
  end

end

if $0 == __FILE__
  require 'rack'
  Rack::Handler::Thin.run(TwitterPush.new, :Port => 4321)
end
