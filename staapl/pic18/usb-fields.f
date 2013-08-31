macro

\ USB descriptor field names for compilation to Flash
\ Both USB descriptors and PIC Flash are little endian.
\ Can't use ",," because words might not be word-address aligned  
  
\ ref: http://www.beyondlogic.org/usbnutshell/usb5.shtml


: w, dup >m #xFF and , m> #x100 / , ;
  
: bLength , ;
: bDescriptorType , ;    
  
\ DEVICE descriptor fields
  
: bcdUSB w, ;
: bDeviceClass , ;
: bDeviceSubClass , ;
: bDeviceProtocol , ;
: bMaxPacketSize , ;
: idVendor w, ;
: idProduct w, ;
: bcdDevice w, ;
: iManufacturer , ;
: iProduct , ;
: iSerialNumber , ;    
: bNumConfigurations , ;

\ CONFIGURATION
    
: wTotalLength w, ;
: bNumInterfaces , ;
: bConfigurationValue , ;
: iConfiguration , ;  
: bmAttributes , ;
: bMaxPower , ;    

\ INTERFACE    
: bInterfaceNumber , ;
: bAlternateSetting , ;
: bNumEndpoints , ;
: bInterfaceClass , ;
: bInterfaceSubClass , ;
: bInterfaceProtocol , ;
: iInterface , ;    

\ ENDPOINT
: bEndpointAddress , ;
: wMaxPacketSize w, ;
: bInterval , ;    



\ Descriptors are tables prefixed with a size field.
: descriptor-size , ;


\ Compile string descriptor:  sym --
: s,
    sym>bin          dup >m
    l:length 2 * 2 + dup >m \ descriptor length
       descriptor-size      \ transport wrapper
    m> bLength
    3  bDescriptorType
    m> ' w, bin, ; \ FIXME: do proper unicode translation
    
forth