require "dolit/version"
require 'ffi'
module Dolit
  extend FFI::Library
  ffi_lib File.dirname(__FILE__) + "/libSiteParser.so"

  typedef :pointer, :id

  # Define :status as an alias for :long on Mac, or :int on other platforms.
  if FFI::Platform.mac?
    typedef :long, :status
  else
    typedef :int, :status
  end

  attach_function :video_parse, :DLVideo_Parse, [:string, :string, :id], :status
  attach_function :video_freevideoresult, :DLVideo_FreeVideoResult, [:id], :void

  def parse(url, user_agent = nil)
    pResult = MemoryPointer.new :pointer
    ret = video_parse(url, user_agent, pResult)

  end
end
