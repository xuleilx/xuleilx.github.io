Doxygen使用
# 注意事项
1. 描述使用 第三人称单数
2. 重载函数，注释写在最后一个函数之前
3. https://www.doxygen.nl/manual/
 1. Documenting the code
 2. Special Commands
# class
```cpp
/**
 * @class XXX XXX.hpp
 *
 * @brief Defines the public data structures and describes the interfaces
 * for XXX.
 */
class XXX{}
```
# function
1. 简述（@brief)，简单介绍该接口的功能。
2. 详述（@details），详细描述该接口的功能，使用业务场景，和该接口相关的其他接口。如果有公式，需要公式展示，介绍以及公式参数介绍。
3. 参数说明（@param），属于出参“[out]”还是入参“[in]”，或者既是出参也是入参“[in,out]”，描述参数的含义、参数类型和取值范围、参数默认值、和参数相关联的数据类型或接口。
4. 返回值（@return）或者（@retval）列举所有的返回值，链接到包含所有返回值的枚举。
@return用来列举可能的返回码，@retval用来对每一个返回的错误码添加含义描述。具体写法详见“API接口doxygen注释举例”章节中API注释示例。
5. 注意事项（@note）
使用该API需注意的事项，例如与该API配对使用的API，是否需要在其他API之前或之后调用该API等，例如，内存分配后，要求用户最好调用cnrtFree释放内存资源。分配的内存是否已初始化？接口调用时如何保证性能等。
6. 环境依赖（@par Requirements）
描述使用该函数需要的头文件、动态库或静态库。如果没有需要写 None，但不可以删除这个章节。
7. 示例（@ par Example）
 a. 同类接口示例代码。
 b. 复杂调用接口示例代码。
 c. 示例代码要按规范写好注释，无需将整个编程流程都写上，但需要写清楚接口各函数的定义、赋值、依赖其他接口的调用等。
```cpp
@retval 每个返回值的具体含义
@return :: 引用之前定义过的
/**
 * @brief Performs brief.
 *
 * @details show details about the function.
 *
 * @param[out] dst The address of destination.
 * @param[in] src The address of source.
 * @param[in,out] in,out param.
 * @retval SUCCESS This API has run successfully.
 * @retval ErrorArgsInvalid This API call failed because of
 *          the input parameter is error.
 * @return
 * :: SUCCESS,
 * :: ERROR_INVALID_VALUE
 *
 * @note
 * - Matters needing attention 
 *
 * @par Requirements
 * - Compute capability and version notes:
 *
 *    - BANG Version: ``__BANG_ARCH__ >= 322`` ;
 *    - CNCC Version: ``cncc --version >= 2.16.0`` ;
 *    - BANG Compute Arch Version: ``cncc --bang-arch >= compute_30`` ;
 *    - MLU Compute Arch Version:  ``cncc --bang-mlu-arch >= tp_322`` .
 *
 * @par Example
 * @code
 *
 *     ...
 *     std::cout<<"Hello World!"<<std::endl;
 *     ...
 *
 * @endcode
 */
 STATUS testfunction(std::string dst,
                     std::string src,
                     int& kernel);
```
# struct
```cpp
    /** @brief Defines the version information for NvSIPLQuery_API.
     */
    typedef struct
    {
        uint32_t uMajor = MAJOR_VER; 
        /**< Holds a major revision. */
        uint32_t uMinor = MINOR_VER; 
        /**< Holds a minor revision. */
        uint32_t uPatch = PATCH_VER; 
        /**< Holds a patch revision. */
    }Version_t;

```
# enum
```cpp
    /** @brief Defines link enable masks for deserializers.
     *
     * @details show details about the enum.
     */
    typedef enum
    {
        LINK_0 = 0x0001, /**< 1st Link */
        LINK_1 = 0x0010, /**< 2nd Link */
        LINK_2 = 0x0100, /**< 3rd Link */
        LINK_3 = 0x1000  /**< 4th Link */
    }Links_t;
```
# union
```cpp
/**
 * information on life time element
 */
typedef union life_time_element {
    int value1;    /**< This is value1 */
    int value2;    /**< This is value2 */
} LifeTime;
```
# group
@defgroup,@ingroup,@addtogroup,@{,@}
