const tip=document.getElementById('tip');
function moveTip(x,y){tip.style.left=Math.max(8,Math.min(x+14,innerWidth-tip.offsetWidth-8))+'px';tip.style.top=(y+14)+'px'}
function showTip(el,x,y){tip.textContent=el.dataset.tip;tip.style.opacity=1;moveTip(x,y)}
document.querySelectorAll('[data-tip]').forEach(el=>{
  el.addEventListener('mouseenter',e=>showTip(el,e.clientX,e.clientY));
  el.addEventListener('mousemove',e=>moveTip(e.clientX,e.clientY));
  el.addEventListener('mouseleave',()=>{tip.style.opacity=0});
  el.addEventListener('focus',()=>{const r=el.getBoundingClientRect();showTip(el,r.left,r.bottom)});
  el.addEventListener('blur',()=>{tip.style.opacity=0});
});
const picker=document.getElementById('week-picker');
function showWeek(){document.querySelectorAll('.week').forEach(w=>{w.hidden=w.dataset.week!==picker.value})}
picker.addEventListener('change',showWeek);
showWeek();
document.querySelectorAll('.week').forEach(week=>{
  const buttons=week.querySelectorAll('.side button'),panes=week.querySelectorAll('.pane');
  buttons.forEach(button=>button.addEventListener('click',()=>{
    buttons.forEach(b=>b.setAttribute('aria-current',String(b===button)));
    panes.forEach(pane=>{pane.hidden=pane.dataset.pane!==button.dataset.target});
  }));
});
function store(fn){try{return fn(localStorage)}catch(e){return null}}
document.querySelectorAll('.actions').forEach(list=>{
  const boxes=[...list.querySelectorAll('input')],note=list.parentElement.querySelector('[data-progress]');
  const update=()=>{note.textContent=boxes.filter(b=>b.checked).length+'/'+boxes.length+' việc đã xong'};
  boxes.forEach(b=>{
    b.checked=store(ls=>ls.getItem('done:'+b.dataset.key))==='1';
    b.addEventListener('change',()=>{store(ls=>ls.setItem('done:'+b.dataset.key,b.checked?'1':'0'));update()});
  });
  update();
});
