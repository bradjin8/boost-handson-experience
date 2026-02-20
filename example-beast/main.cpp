// Minimal Boost.Beast usage: HTTP GET example (header-only usage)
#include <boost/beast/core.hpp>
#include <boost/beast/http.hpp>
#include <boost/beast/version.hpp>
#include <iostream>

namespace beast = boost::beast;
namespace http = beast::http;

int main() {
    std::cout << "Boost.Beast version: " << BOOST_BEAST_VERSION << "\n";
    // Use a simple type from Beast to verify linkage
    http::request<http::string_body> req{http::verb::get, "/", 11};
    req.set(http::field::host, "example.com");
    req.set(http::field::user_agent, BOOST_BEAST_VERSION_STRING);
    std::cout << "Beast HTTP request type ready.\n";
    return 0;
}
