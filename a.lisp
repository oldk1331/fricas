(sb-alien:with-alien ((buf (sb-alien:array sb-alien:char 20480)))
  (alien-funcall (extern-alien "memset" (function void system-area-pointer int size-t))
    (sb-alien:alien-sap buf ) 0 20480))
