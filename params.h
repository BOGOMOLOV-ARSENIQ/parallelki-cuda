#pragma once
#include <string>

const int WORKERS = 6;
const long long TOTAL = 1'000'000'000;

inline void make_password(long long i, std::string &pw) {
    for (int p = 8; p >= 0; p--) {
        pw[p] = char('0' + i % 10);
        i /= 10;
    }
}
