unsigned volatile char * gpio_led = (unsigned char *) 0x41200000;

int csd_main()
{

 int count;
 int i;
 for (i=0;i<1;i++) {

	for (count=0; count < 0x300000; count++) ;

	*gpio_led = 0xC3;

	for (count=0; count < 0x300000; count++) ;

	*gpio_led = 0x3C;

 }
	return 0;
}
