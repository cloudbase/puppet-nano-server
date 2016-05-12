require 'ffi'

module Dir::Constants
  include FFI::Library

  private

  FILE_DEVICE_FILE_SYSTEM      = 0x00000009
  FILE_FLAG_OPEN_REPARSE_POINT = 0x00200000
  FILE_FLAG_BACKUP_SEMANTICS   = 0x02000000
  FILE_ATTRIBUTE_DIRECTORY     = 0x00000010
  FILE_ATTRIBUTE_REPARSE_POINT = 0x00000400
  ERROR_ALREADY_EXISTS         = 183
  METHOD_BUFFERED              = 0
  OPEN_EXISTING                = 3
  GENERIC_READ                 = 0x80000000
  GENERIC_WRITE                = 0x40000000
  SHGFI_DISPLAYNAME            = 0x000000200
  SHGFI_PIDL                   = 0x000000008

  # ((DWORD)-1)
  INVALID_FILE_ATTRIBUTES = 0xFFFFFFFF

  # ((HANDLE)-1)
  INVALID_HANDLE_VALUE = FFI::Pointer.new(-1).address
end
