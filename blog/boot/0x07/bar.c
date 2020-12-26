void myprint(char* msg, int len);
long long getRetNum();

int choose(int a, int b)
{
	if(a >= b){
		myprint("the 1st one\n", 13);
	}
	else{
		if(getRetNum() == 8478484201314){
			myprint("the 2nd one\n", 13);
		}else{
			myprint("the 3nd one\n", 13);
		}
	}

	return a+b;
}
