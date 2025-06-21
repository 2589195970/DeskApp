<template>
  <div id="app">
    <div class="title">解锁键盘,并退出考试程序</div>
    <div class="tips">tips: 该页面为管理员预留界面,考生请勿尝试自觉关闭</div>
    <div><input type="password" v-model="password" placeholder="请输入解锁密码"></div>
    <div class="btn-group">
      <button class="btn1" @click="okUnClok">确认密码</button>
      <button class="btn2" @click="closeWindow">关闭解锁窗口</button>
    </div>
  </div>
</template>

<script>
  const { ipcRenderer } = window.electron;
export default {
  name: 'App',
  data() {
    return {
      password: ''
    }
  },
  methods: {
    okUnClok() {
      if (this.password == '') {
        return;
      }
      ipcRenderer.send('userWantCloseTheApp',this.password)
    },
    closeWindow(){
      ipcRenderer.send('userCloseUnLockWindow',true)
    }
  },
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
.title{
  font-size: 32px;
  font-weight: bold;
}
.tips{
  font-size: 16px;
  color: gray;
  margin-top: 1px;
}
input{
 -webkit-appearance: none;
  background-color: #fff;
  background-image: none;
  border-radius: 4px;
  border: 1px solid #DCDFE6;
  box-sizing: border-box;
  color: #555;
  display: inline-block;
  font-size: inherit;
  height: 40px;
  line-height: 40px;
  outline: none;
  padding: 0 15px;
  transition: border-color 0.2s cubic-bezier(0.645, 0.045, 0.355, 1);
  width: 320px;
  font-size: 22px;
  margin-top: 60px;
}
.btn-group{
  margin-top: 20px;
}

button {
  display: inline-block;
  line-height: 1;
  white-space: nowrap;
  cursor: pointer;
  background: #fff;
  border: 1px solid #DCDFE6;
  border-color: #DCDFE6;
  color: #555;
  -webkit-appearance: none;
  text-align: center;
  box-sizing: border-box;
  outline: none;
  margin: 0;
  transition: .1s;
  font-weight: 500;
  -moz-user-select: none;
  -webkit-user-select: none;
  -ms-user-select: none;
  padding: 12px 20px;
  font-size: 14px;
  border-radius: 4px;
}
.btn1{
  color: #fff;
  background-color: #D40000;
  border-color: #D40000;
}
.btn2{
  margin-left: 30px;
  color: #fff;
  background-color: #20C1BD;
  border-color: #20C1BD;
}
</style>
