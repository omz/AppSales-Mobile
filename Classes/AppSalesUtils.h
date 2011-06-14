


#if !defined(APPSALES_DEBUG) || APPSALES_DEBUG == 0
	#define APPSALESLOG(...) do {} while (0)
#else
	#define APPSALESLOG(...) NSLog(__VA_ARGS__)
#endif


#define ASSERT_IS_MAIN_THREAD() NSAssert([NSThread isMainThread], @"must call from main thread");
#define ASSERT_NOT_MAIN_THREAD() NSAssert([NSThread isMainThread] == false, @"do not call from main thread");

#define RELEASE_SAFELY(__PTR) { [__PTR release]; __PTR = nil; }

static inline id ASSERT_NOT_NULL(id __PTR) {
    NSCAssert(__PTR, nil);
    return __PTR;
}


__attribute__((constructor)) // run this function run when the app loads
static void InitRandom() {
	srandom(time(NULL));
}

//  returns a random float between 0 and 1
static inline float random_0_1() {
    return random() / (float)0x7fffffff;
}


NSString* getDocPath();
