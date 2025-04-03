package stx.log.transport.web;

import haxe.Serializer;
using tink.CoreApi;
using stx.Pico;
using eu.ohmrun.Stig;
using eu.ohmrun.Datura;
using stx.Log;
using stx.Fail;
using stx.Coroutine;
using stx.coroutine.Core;

class Server{
  static public function main(){
    final server = new DaturaServer().source(
            () -> __.success(Server_Config(DaturaOptions.unit()))
          ).emiter(
            (x) -> Server_Exception(__.fault().of(DaturaFailure.E_Datura_UnexpectedEndCondition))
          );
    function driver(self:Emiter<DaturaServerMessage,DaturaFailure>):Emiter<DaturaServerMessage,DaturaFailure>{
      trace('drive: $self');
      return switch(self){
        case Emit(Server_Error(_,userNr,reason),_) : 
          __.exit(__.fault().of(E_Datura(reason,"",userNr)));
        case Emit(Server_Data(server, userNr, bytes),next) : 
          final string = bytes.toString();
          final data   : StigNode = Stig.instance.decode(string);
          trace(data);
           js.html.Console.log(data.toObject());
          next.app(driver);  
        case Emit(x,next) : 
          // trace(x);
          next.app(driver); 
        default :
          trace(self.is_concrete()); 
          self;
      }
    } 
    final future = server.app(driver).asEmiter().pocket(
      x -> {}
    ).run();

    future.handle(
      o -> o.fold(
        x -> {
          Console.log(x);
        },
        () -> {}
      )
    );
  }
  
}