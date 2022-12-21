require "ffi"

# https://stackoverflow.com/a/22307622
module Mac
  module CoreGraphics
    extend FFI::Library

    ffi_lib "/System/Library/Frameworks/CoreGraphics.framework/Resources/BridgeSupport/CoreGraphics.dylib"

    attach_function :CGEventSourceSecondsSinceLastEventType, [:int, :uint32], :double

    def self.idle_time
      CoreGraphics.CGEventSourceSecondsSinceLastEventType(1, 4294967295)
    end
  end
end
