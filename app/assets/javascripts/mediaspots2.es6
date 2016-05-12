class AnalitycsModule {  
  constructor(name) {
    this.name = name;
  }

  sayName() {
    console.log(this.name);
  }


  get nameCount() {
    return 1234;
  }

  
}

var a = new AnalitycsModule('test es6');
a.sayName();
console.log(a.name);
console.log(a.nameCount);
