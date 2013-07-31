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

  def self.parse(url, user_agent = nil)
    pResult = FFI::MemoryPointer.new :pointer
    ret = video_parse(url, user_agent, pResult)
    return if ret != 0
    pos = 0
    res = {}
    pVideoResult = pResult.read_pointer
    res[:site_id] = pVideoResult.get_int(pos)
    pos += 4
    res[:time_length] = pVideoResult.get_long(pos)
    pos += 8
    res[:framCount] = pVideoResult.get_long(pos)
    pos += 8
    res[:total_size] = pVideoResult.get_long(pos)
    pos += 8
    res[:v_name] = pVideoResult.get_pointer(pos).read_string
    pos += 4
    res[:tags] = pVideoResult.get_pointer(pos).read_string
    pos += 4
    count = pVideoResult.get_int(pos)
    pos += 4
    pTypePtr = pVideoResult.get_pointer(pos)
    pos += 4
    if count > 0
      p = 0
      res[:strs] = []
      count.times do |i|
        type_hash = {}
        type_hash[:str_type] = pTypePtr.get_pointer(p).read_string
        p += 4
        segCount = pTypePtr.get_int(p)
        p += 4
        pSegPtr = pTypePtr.get_pointer(p)
        p += 4

        if segCount > 0
          type_hash[:files] = []
          segPinterPos = 0
          segCount.times do |j|
            file_hash = {}
            file_hash[:file_size] = pSegPtr.get_long(segPinterPos)
            segPinterPos += 8
            file_hash[:seconds] = pSegPtr.get_int(segPinterPos)
            segPinterPos += 4
            file_hash[:file_no] = pSegPtr.get_int(segPinterPos)
            segPinterPos += 4
            file_hash[:url] = pSegPtr.get_pointer(segPinterPos).read_string
            segPinterPos += 4
            type_hash[:files][j] = file_hash
          end
        end
        res[:strs][i] = type_hash
      end
    end
    video_freevideoresult(pVideoResult)
    res
  end
end
