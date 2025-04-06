package env

import "os"

type Env string

var (
	None Env = ""
	Dev  Env = "Dev"
)

func Lookup() (Env, bool) {
	env, ok := os.LookupEnv("ENVIRONMENT")
	return Env(env), ok
}

func Current() Env {
	if env, ok := Lookup(); ok {
		return env
	} else {
		return None
	}
}

func IsDev() bool {
	return Current() == Dev
}
