# THPythonExecutor
A simple demo for calling python methods in an iOS project and handling their return values.

### 前言

想必大家都知道 Python 是一个最近几年火到爆炸的语言。大数据、机器学习、爬虫、自动化运维balabala一大堆应用。良好的可读性，对于上手难度也不会门槛太高。

之前公司项目中有做导航 App，我带搜索小组。功能交互啥玩意的都基本上定好了，但是有一些国外商业化数据太贵也不够全面，数据可新等级也不咋地，没米下锅啊。负责做数据分析的大哥就 pa 了上亿条 POI 数据，🐂上天。（当然还是要遵纪守法）

今天本文仅是在项目中嵌入 Python 编译环境，然后调用 Python 中的方法，并解析返回值。另鉴于本人 Python 菜鸡选手，如果错误还请不吝指教。

### Python 之初印象

1. Python 是面向对象的编程语言。它的类支持多态、多重继承等等高级 OOP 概念。当然像 C++ 一样，Python 支持面向对象编程，也支持面向过程编程的模式。

2. Python 是一种解释型语言。目前 Python 的标准实现方式是将源代码的语句转为字节码格式，通过解释器解释。Python 没有将代码编译成二进制代码，所以相较于 C 和 C++ 等编译型语言，Python的执行速度会有数量级上的差异。

3. Python 提供了完备的基础代码库，有网络、正则、多线程、GUI、数据库、等等等。当然了，除了内置的库外，Python 还有大量的第三方轮子，供你享用。

4. Python 可被嵌入到其他语言开发的程序中。Python 解析器能很方便地执行代码和 debug，可作为一个编程接口嵌入一个应用程序中。且 Python 解释器负责管理 Python 的内存管理。

以上几点中第4点就是本文主要实践和探索的：

在 OC 项目中调用 Python 方法，并处理返回值。你问我有啥意义？搞事情啊

1. 内嵌 Python 解释器后，N 多轮子供你使用。

2. 脚本可以动态化，就像游戏开发时候很多用 lua 来进行动态化。

好了，开干。

### 项目配置

#### Python解释器

github 上有大佬写了个[Python Apple Support](https://github.com/beeware/Python-Apple-support)

#### 配置项目编译环境

新建 Xcode 项目(本文是iOS 15 SDK)

本文项目中使用的是[Python-3.8-iOS-support.b7](https://github.com/beeware/Python-Apple-support/releases/tag/3.8-b7)

![截屏2021-08-23 上午12.06.58](https://tva1.sinaimg.cn/large/008i3skNgy1gtqqu325hcj60mw082glz02.jpg)

然后在 Link Binary With Libraries 中加入缺失的依赖库 libsqlite3.tbd、libz.tbd。具体的步骤不再赘述，可以参考[demo](https://github.com/cocoonbud/THPythonExecutor)

### 具体实践

#### 设置 PythonPath、PythonHome 然后初始化

```objective-c
//设置 python 环境变量（包含项目资源文件目录、其他 Python 文件目录）
NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"Python_script" ofType:@"bundle"];

NSArray *pythonPathArr = [NSArray arrayWithObjects:resourcePath, [resourcePath stringByAppendingPathComponent:@" "], [resourcePath stringByAppendingPathComponent:@"Python"], nil];

int setenvRes = setenv("PYTHONPATH", [[pythonPathArr componentsJoinedByString:@":"] UTF8String], 1);

//这里的路径结合 demo 去理解
NSString *pythonHome = [NSString stringWithFormat:@"%@/Python3.8.bundle/Resources", [[NSBundle mainBundle] resourcePath], nil];

wchar_t *wPythonHome = Py_DecodeLocale([pythonHome UTF8String], NULL);

Py_SetPythonHome(wPythonHome);

//解初始化 Python 解析器
Py_Initialize();

//检测是否初始化成功
if (!Py_IsInitialized()) {

	return -1;

}
```

#### run 一个简单的 python 脚本

```objective-c
PyRun_SimpleString("print('oc project calls python methods')");
```

#### run 一个简单的 Python 文件

```objective-c
NSString *path = [[NSBundle mainBundle] pathForResource:@"XX" ofType:@"py"];

FILE *file = fopen([path UTF8String], "r");

PyRun_SimpleFile(mainfileFile, (char *)[[scriptPath lastPathComponent] UTF8String]);
```

对于 run 完后，我们要释放，需要调用`Py_Finalize()`。

#### OC 传参调用 Python 方法，然后解析 Python 返回值

这个操作的流程，基本就是找到 Python 文件，找到 Python 的 class，然后找到对应的方法，转换参数，填入参数。然后解析返回值 callback。

```objective-c
//导入模块
PyObject *pModule = PyImport_ImportModule(fileName);

//根据类名获得类
PyObject *pyClass = PyObject_GetAttrString(pModule, [className UTF8String]);

//创建实例
PyObject *pyInstance = PyInstanceMethod_New(pyClass);

//参数序列化
NSError *error = nil;

NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameter options:NSJSONWritingPrettyPrinted error:&error];

NSString *paramterJsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

//调用 Python 方法
PyObject *result = PyObject_CallMethod(pyInstance, [methodName UTF8String], "(N,s)", [paramterStr UTF8String]);

char *cStr = NULL;

//把 Python 方法的返回值解析为 char
PyArg_Parse(result, "s", &cStr);
```

怎么样，简单吧。看到这，何不如亲自动手试试？

### 一些补充

1. 有两个宏 `Py_INCREF(pObj)` 和 `Py_DECREF(pObj)` 被用于增和减引用计数 reference counts。当引用计数为0时，释放对象。一般调用Py_Something的函数需要去调用下 `Py_DECREF()`。有兴趣再多了解的可搜Python的引用计数。

2. 本文 demo 中引入的 Python 以及需要的编译依赖资源过大。不像 OC 项目嵌入 lua 解释器只需要非常少的空间即可。

3. 之前也有看到过用 Python 开发 iOS 项目，感兴趣的可以去 google 上搜[Build a Mobile Application with Python](https://www.google.com.hk/search?q=Build+a+Mobile+Application+with+Python&oq=Build+a+Mobile+Application+with+Python&aqs=chrome..69i57.653j0j4&sourceid=chrome&ie=UTF-8)或者直接搜索 [kivy](https://github.com/kivy/kivy) 这个 Python 开发框架。

4. 解析返回值`PyObject *results`，单个返回值：`PyArg_Parse()`，多返回值：`PyArg_ParseTuple()`。

5. 本文用到的 libPython.a 因为太大，上传 github 时候提示超过100MB上传失败。所以后来用了 Git LFS。[Git LFS的简单介绍](https://juejin.cn/post/6998094133701115911)

### 本文 Demo

[THPythonExecutor](https://github.com/cocoonbud/THPythonExecutor)

### 其他

[C++ 调用 Python 脚本](https://zhuanlan.zhihu.com/p/79896193)

[Embedding Python in Another Application](https://docs.python.org/3/extending/embedding.html?highlight=pyarg_parsetuple)
