// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string.h>

void* memset(void* _dst, int c, size_t n) {
    uint8_t* dst = _dst;
    while (n-- > 0) {
        *dst++ = c;
    }
    return _dst;
}

void* memcpy(void* _dst, const void* _src, size_t n) {
    uint8_t* dst = _dst;
    const uint8_t* src = _src;
    while (n-- > 0) {
        *dst++ = *src++;
    }
    return _dst;
}

int memcmp(const void* _a, const void* _b, size_t n) {
    const uint8_t* a = _a;
    const uint8_t* b = _b;
    while (n-- > 0) {
        int x = *a++ - *b++;
        if (x != 0) {
            return x;
        }
    }
    return 0;
}

size_t strlen(const char* s) {
    size_t len = 0;
    while (*s++)
        len++;
    return len;
}

size_t strnlen(const char* s, size_t max) {
    size_t len = 0;
    while (len < max && *s++)
        len++;
    return len;
}

char* strchr(const char* s, int c) {
    while (*s != c && *s++) ;
    if (*s != c) return 0;
    return (char*)s;
}

char* strcpy(char* dst, const char* src) {
    while (*src != 0) {
        *dst++ = *src++;
    }
    return dst;
}

char* strncpy(char* dst, const char* src, size_t len) {
    while (len-- > 0 && *src != 0) {
        *dst++ = *src++;
    }
    return dst;
}

int strcmp(const char* s1, const char* s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *s1 - *s2;
}

int strncmp(const char* s1, const char* s2, size_t len) {
    while (len-- > 0) {
        int diff = *s1 - *s2;
        if (diff != 0 || *s1 == '\0') {
            return diff;
        }
        s1++;
        s2++;
    }
    return 0;
}


static int isspace(int c)
{
  return ((c == ' ') || (c == '\n') || (c == '\t'));
}

static int isdigit(int c)
{
  return ((c >= '0') && (c <= '9'));
}

int isalpha(int c)
{
	/*
	 * Depends on ASCII-like character ordering.
	 */
	return ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ? 1 : 0);
}

char isupper (unsigned char c)
{
#define UC(c)	((unsigned char)c)
    if ( c >= UC('A') && c <= UC('Z') )
        return 1;
    return 0;
}

long strtol(const char *nptr, char **endptr, int base)
{
#define LONG_MAX        9223372036854775807L
#define LONG_MIN        (-LONG_MAX - 1L)
	const char *s;
	long acc, cutoff;
	int c;
	int neg, any, cutlim;
	/*
	 * Skip white space and pick up leading +/- sign if any.
	 * If base is 0, allow 0x for hex and 0 for octal, else
	 * assume decimal; if base is already 16, allow 0x.
	 */
	s = nptr;
	do {
		c = (unsigned char) *s++;
	} while (isspace(c));
	if (c == '-') {
		neg = 1;
		c = *s++;
	} else {
		neg = 0;
		if (c == '+')
			c = *s++;
	}
	if ((base == 0 || base == 16) &&
	    c == '0' && (*s == 'x' || *s == 'X')) {
		c = s[1];
		s += 2;
		base = 16;
	}
	if (base == 0)
		base = c == '0' ? 8 : 10;
	/*
	 * Compute the cutoff value between legal numbers and illegal
	 * numbers.  That is the largest legal value, divided by the
	 * base.  An input number that is greater than this value, if
	 * followed by a legal input character, is too big.  One that
	 * is equal to this value may be valid or not; the limit
	 * between valid and invalid numbers is then based on the last
	 * digit.  For instance, if the range for longs is
	 * [-2147483648..2147483647] and the input base is 10,
	 * cutoff will be set to 214748364 and cutlim to either
	 * 7 (neg==0) or 8 (neg==1), meaning that if we have accumulated
	 * a value > 214748364, or equal but the next digit is > 7 (or 8),
	 * the number is too big, and we will return a range error.
	 *
	 * Set any if any `digits' consumed; make it negative to indicate
	 * overflow.
	 */
	cutoff = neg ? LONG_MIN : LONG_MAX;
	cutlim = cutoff % base;
	cutoff /= base;
	if (neg) {
		if (cutlim > 0) {
			cutlim -= base;
			cutoff += 1;
		}
		cutlim = -cutlim;
	}
	for (acc = 0, any = 0;; c = (unsigned char) *s++) {
		if (isdigit(c))
			c -= '0';
		else if (isalpha(c))
			c -= isupper(c) ? 'A' - 10 : 'a' - 10;
		else
			break;
		if (c >= base)
			break;
		if (any < 0)
			continue;
		if (neg) {
			if (acc < cutoff || (acc == cutoff && c > cutlim)) {
				any = -1;
				acc = LONG_MIN;
			} else {
				any = 1;
				acc *= base;
				acc -= c;
			}
		} else {
			if (acc > cutoff || (acc == cutoff && c > cutlim)) {
				any = -1;
				acc = LONG_MAX;
			} else {
				any = 1;
				acc *= base;
				acc += c;
			}
		}
	}
	if (endptr != 0)
		*endptr = (char *) (any ? s - 1 : nptr);
	return (acc);
}

