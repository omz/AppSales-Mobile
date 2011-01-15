


#if !defined(APPSALES_DEBUG) || APPSALES_DEBUG == 0
	#define APPSALESLOG(...) do {} while (0)
#else
	#define APPSALESLOG(...) NSLog(__VA_ARGS__)
#endif


__attribute__((constructor)) // run this function run when the app loads
static void InitRandom() {
	srandom(time(NULL));
}

//  returns a random float between 0 and 1
static inline float random_0_1() {
    return random() / (float)0x7fffffff;
}


NSString* getDocPath();
