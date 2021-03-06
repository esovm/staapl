\ FIXME: convert to new usb support

staapl pic18/string
staapl pic18/route
load usb-fields.f

\ Flat USB descriptor layout.  This is a little raw, but the manual
\ effort required to fill out lengths and string indices pays back in
\ ease of debugging and specs cross-referencing.


\ ref: http://www.beyondlogic.org/usbnutshell/usb5.shtml
  
    
: device-descriptor \ - lo hi
    table->
    18 descriptor-size
    \ -----------------
    
    18     bLength
    1      bDescriptorType
    #x110  bcdUSB
    0      bDeviceClass \ Defined at interface level
    0      bDeviceSubClass
    0      bDeviceProtocol
    64     bMaxPacketSize
    #x05F9 idVendor
    #xFFFF idProduct
    0      bcdDevice
    \ Strings
    1      iManufacturer
    2      iProduct
    3      iSerialNumber
    1      bNumConfigurations

: configuration-descriptor \ n -- lo hi
    drop \ FIXME: only support one configuration

    table->
    9 9 + 7 + 7 + descriptor-size
    \ -----------------
    
    \ CONFIGURATION
    9      bLength
    2      bDescriptorType

    9 9 + 7 + 7 + wTotalLength
    
    1      bNumInterfaces
    1      bConfigurationValue
    4      iConfiguration
    #xA0   bmAttributes \ remote wakeup
    #x32   bMaxPower    \ 100 mA
    
    \ INTERFACE
    9      bLength
    4      bDescriptorType
    0      bInterfaceNumber
    0      bAlternateSetting
    2      bNumEndpoints
    #xFF   bInterfaceClass \ Vendor-specific
    0      bInterfaceSubClass
    0      bInterfaceProtocol
    5      iInterface

    \ ENDPOINT
    7      bLength
    5      bDescriptorType
    #x81   bEndpointAddress \ IN1
    #x02   bmAttributes     \ BULK
    64     wMaxPacketSize
    0      bInterval
    
    \ ENDPOINT
    7      bLength
    5      bDescriptorType
    #x01   bEndpointAddress \ OUT1
    #x02   bmAttributes     \ BULK
    64     wMaxPacketSize
    0      bInterval


\ -- lo hi
: string-languages table-> 4 , 4 , 3 , #x09 , #x4 , \ US English
: snull            table-> 2 , 2 , 3 , 

: string-1 table-> ` Zwizwa s, ;
: string-2 table-> ` Staapl s, ;
: string-3 table-> ` um0 s, ;    
: string-4 table-> ` Configuration s, ;
: string-5 table-> ` Staapl_Serial_Console s, ;
    
: string-descriptor \ n - lo hi
    7 and route
    string-languages .
    string-1 .
    string-2 .
    string-3 .
    string-4 .
    string-5 .
    snull .
    snull ;

    