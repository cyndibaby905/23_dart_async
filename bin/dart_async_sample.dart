import 'dart:async';
import 'dart:isolate';


sample1() {
  Future(() => print('f1'));
  Future(() => print('f2'));
//f3执行后会立刻同步执行then 3
  Future(() => print('f3')).then((_) => print('then 3'));
//then 4会加入微任务队列，尽快执行
  Future(() => null).then((_) => print('then 4'));
}


sample2() {
  Future(() => print('f1'));//声明一个匿名Future
  Future fx = Future(() => null);//声明Future fx，其执行体为null

//声明一个匿名Future，并注册了两个then。在第一个then回调里启动了一个微任务
  Future(() => print('f2')).then((_) {
    print('f3');
    scheduleMicrotask(() => print('f4'));
  }).then((_) => print('f5'));

//声明了一个匿名Future，并注册了两个then。第一个then是一个Future
  Future(() => print('f6'))
      .then((_) => Future(() => print('f7')))
      .then((_) => print('f8'));

//声明了一个匿名Future
  Future(() => print('f9'));

//往执行体为null的fx注册了了一个then
  fx.then((_) => print('f10'));

//启动一个微任务
  scheduleMicrotask(() => print('f11'));
  print('f12');

}

Future<String> fetchContent() =>
    Future<String>.delayed(Duration(seconds:2), () => "Hello")
        .then((x) => "$x 2019");

sample4() {
  Future(() => print('f1'))
      .then((_) async => await Future(() => print('f2')))
      .then((_) => print('f3'));
  Future(() => print('f4'));
}

doSth(msg) => print(msg);

func() async => print(await fetchContent());

Isolate isolate;

start() async {
  ReceivePort receivePort= ReceivePort();//创建管道
  //创建并发Isolate，并传入发送管道

  isolate = await Isolate.spawn(getMsg, receivePort.sendPort);
  //监听管道消息
  receivePort.listen((data) {
  print('Data：$data');
  receivePort.close();//关闭管道
  isolate?.kill(priority: Isolate.immediate);//杀死并发Isolate
  isolate = null;
  });
}

getMsg(sendPort) => sendPort.send("Hello");

//并发计算阶乘
Future<dynamic> asyncFactoriali(n) async{
  final response = ReceivePort();//创建管道
  //创建并发Isolate，并传入管道
  await Isolate.spawn(_isolate,response.sendPort);
  //等待Isolate回传管道
  final sendPort = await response.first as SendPort;
  //创建了另一个管道answer
  final answer = ReceivePort();
  //往Isolate回传的管道中发送参数，同时传入answer管道
  sendPort.send([n,answer.sendPort]);
  return answer.first;//等待Isolate通过answer管道回传执行结果
}

//Isolate函数体，参数是主Isolate传入的管道
_isolate(initialReplyTo) async {
  final port = ReceivePort();//创建管道
  initialReplyTo.send(port.sendPort);//往主Isolate回传管道
  final message = await port.first as List;//等待主Isolate发送消息(参数和回传结果的管道)
  final data = message[0] as int;//参数
  final send = message[1] as SendPort;//回传结果的管道 
  send.send(syncFactorial(data));//调用同步计算阶乘的函数回传结果
}

//同步计算阶乘
int syncFactorial(n) => n < 2 ? n : n * syncFactorial(n-1);


void main() async {
  print(".......sample1.......");
  sample1();
  await Future.delayed(const Duration(seconds: 1), () => print(".......sample2......."));
  sample2();
  await Future.delayed(const Duration(seconds: 1), () => print(".......sample3......."));
  print(await fetchContent());//等待Hello 2019的返回
  await Future.delayed(const Duration(seconds: 1), () => print(".......sample4......."));
  sample4();
  await Future.delayed(const Duration(seconds: 1), () => print(".......sample5......."));
  print("func before");
  func();
  print("func after");
  await Future.delayed(const Duration(seconds: 2), () => print(".......sample6......."));
  Isolate.spawn(doSth, "Hi");
  await Future.delayed(const Duration(seconds: 1), () => print(".......sample7......."));
  start();
  await Future.delayed(const Duration(seconds: 1), () => print(".......sample8......."));
  print(await asyncFactoriali(4));
  //await Future.delayed(const Duration(seconds: 1), () => print(".......sample9......."));
  //compute函数仅能在Flutter工程中使用
  //print(await compute(syncFactorial, 4));

}
