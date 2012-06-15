/**
 * FastClick: Set up handling of fast clicks
 *
 * On touch WebKit (eg Android, iPhone) onclick events are usually 
 * delayed by ~300ms to ensure that they are clicks rather than other
 * interactions such as double-tap to zoom.
 *
 * To work around this, add a document listener which converts touches
 * to clicks on a global basis, excluding scrolls and gestures.  The 
 * default click events are then cancelled to prevent double-clicks.
 *
 * This function automatically adapts if no action is required (eg if 
 * touch events are not supported), and also handles functionality such
 * as preventing actions in the page while the section selector
 * is displaying.
 *
 * One alternative is to use ontouchend events for everything, but that
 * prevents non-touch interaction, and
 * requires checks everywhere to ensure that a touch wasn't a 
 * scroll/swipe/etc.
 *
 * ------
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the 
 * "Software"), to deal in the Software without restriction, including 
 * without limitation the rights to use, copy, modify, merge, publish, 
 * distribute, sublicense, and/or sell copies of the Software, and to 
 * permit persons to whom the Software is furnished to do so, subject 
 * to the following conditions:
 * 
 * The below copyright notice and this permission notice shall be 
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN 
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
 * SOFTWARE.
 *
 * @licence MIT License (http://www.opensource.org/licenses/mit-license.php)
 * @copyright (c) 2011 Assanka Limited
 * @author Rowan Beentje <rowan@assanka.net>, Matt Caruana Galizia <matt@assanka.net>
 */

var FastClick=(function(){var a='ontouchstart' in window;return function(e){if(!(e instanceof HTMLElement)){throw new TypeError("Layer must be instance of HTMLElement")}if(a){e.addEventListener("touchstart",g,true);e.addEventListener("touchmove",f,true);e.addEventListener("touchend",i,true);e.addEventListener("touchcancel",b,true)}e.addEventListener("click",h,true);if(e.onclick instanceof Function){e.addEventListener("click",e.onclick,false);e.onclick=""}var d={x:0,y:0,scroll:0},c=false;function g(j){c=true;d.x=j.targetTouches[0].clientX;d.y=j.targetTouches[0].clientY;d.scroll=window.pageYOffset;return true}function f(j){if(c){if(Math.abs(j.targetTouches[0].clientX-d.x)>10||Math.abs(j.targetTouches[0].clientY-d.y)>10){c=false}}return true}function i(l){var k,j;if(!c||Math.abs(window.pageYOffset-d.scroll)>5){return true}k=document.elementFromPoint(d.x,d.y);if(k.nodeType===Node.TEXT_NODE){k=k.parentNode}if(!(k.className.indexOf("clickevent")!==-1&&k.className.indexOf("touchandclickevent")===-1)){j=document.createEvent("MouseEvents");j.initMouseEvent("click",true,true,window,1,0,0,d.x,d.y,false,false,false,false,0,null);j.forwardedTouchEvent=true;k.dispatchEvent(j)}if(!(k instanceof HTMLSelectElement)&&k.className.indexOf("clickevent")===-1){l.preventDefault()}else{return false}}function b(j){c=false}function h(l){if(!window.event){return true}var m=true;var k;var j=window.event.forwardedTouchEvent;if(a){k=document.elementFromPoint(d.x,d.y);if(!k||(!j&&k.className.indexOf("clickevent")==-1)){m=false}}if(m){return true}l.stopPropagation();l.preventDefault();l.stopImmediatePropagation();return false}}})();