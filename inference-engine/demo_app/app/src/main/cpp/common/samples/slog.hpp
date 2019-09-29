// Copyright (C) 2018-2019 Intel Corporation
// SPDX-License-Identifier: Apache-2.0
//

/**
 * @brief a header file with logging facility for common samples
 * @file log.hpp
 */

#pragma once

#include <string>
#include <sstream>
#include <android/log.h>
#ifndef LOG_TAG
#define LOG_TAG "SLOG_WRAPPER"
#endif
namespace slog {

/**
 * @class LogStreamEndLine
 * @brief The LogStreamEndLine class implements an end line marker for a log stream
 */
class LogStreamEndLine { };

static constexpr LogStreamEndLine endl;


/**
 * @class LogStreamBoolAlpha
 * @brief The LogStreamBoolAlpha class implements bool printing for a log stream
 */
class LogStreamBoolAlpha { };

static constexpr LogStreamBoolAlpha boolalpha;


/**
 * @class LogStream
 * @brief The LogStream class implements a stream for sample logging
 */
class LogStream {
    std::string _prefix;
    std::ostream* _log_stream;
    bool _new_line;

public:
    /**
     * @brief A constructor. Creates an LogStream object
     * @param prefix The prefix to print
     */
    LogStream(const std::string &prefix, std::ostream& log_stream)
            : _prefix(prefix), _new_line(true) {
        _log_stream = &log_stream;
        _log_stream = NULL; //set null flag to forward to sstream and then android log
    }

    /**
     * @brief A stream output operator to be used within the logger
     * @param arg Object for serialization in the logger message
     */
    template<class T>
    LogStream &operator<<(const T &arg) {
        if (_new_line) {
			if (_log_stream) {
            (*_log_stream) << "[ " << _prefix << " ] ";
			}
			else {
				ss << "[ " << _prefix << " ] ";
			}
            _new_line = false;
        }

		if (_log_stream) {
        (*_log_stream) << arg;
		}
		else {
			ss << arg;
		}
        return *this;
    }

    // Specializing for LogStreamEndLine to support slog::endl
    LogStream& operator<< (const LogStreamEndLine &/*arg*/) {
        _new_line = true;

		if (_log_stream) {
        (*_log_stream) << std::endl;
		}else {
			ss <<std::endl;
			//printf("ss:%d=%s", ss.str().length(), ss.str().c_str());
            __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "%s", ss.str().c_str());
			ss.str("");
		}
        return *this;
    }

    // Specializing for LogStreamBoolAlpha to support slog::boolalpha
    LogStream& operator<< (const LogStreamBoolAlpha &/*arg*/) {
		if (_log_stream) {
        (*_log_stream) << std::boolalpha;
		}else {
        ss << std::boolalpha;
		}
        return *this;
    }
private:
	//std::ostringstream  ss;
	std::stringstream ss;
};


static LogStream info("INFO", std::cout);
static LogStream warn("WARNING", std::cout);
static LogStream err("ERROR", std::cerr);

}  // namespace slog
