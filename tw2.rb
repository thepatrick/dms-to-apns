#!/usr/bin/env ruby

# Copyright (c) 2010 Patrick Quinn-Graham
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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

    build_up_ssl if @ssl.nil? or @sock.nil? 

    begin
      @ssl.write(notification_packet)
    rescue
      clean_up_ssl
      build_up_ssl 
      @ssl.write(notification_packet)
    end

    clean_up_ssl #if (@ssl and  @ssl.eof?) or (@sock and @sock.eof?)

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
