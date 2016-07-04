dim a as integer
dim b as integer

a = &h0000

b = &hF00F

&h0000
&h000F
&h00FF
&h0FFF
&hFFFF
&hFFF0
&hFF00
&hF000
&hF0F0
&h0F0F
&hF0FF
&hFF0F
&hFFFF
&hF00F
&h0FF0


print hex(b or a)
sleep
