/* -*-mode:java; c-basic-offset:2; indent-tabs-mode:nil -*- */
/*
Copyright (c) 2001 Lapo Luchini.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice,
     this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright 
     notice, this list of conditions and the following disclaimer in 
     the documentation and/or other materials provided with the distribution.

  3. The names of the authors may not be used to endorse or promote products
     derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESSED OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHORS
OR ANY CONTRIBUTORS TO THIS SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/*
 * This program is based on zlib-1.1.3, so all credit should go authors
 * Jean-loup Gailly(jloup@gzip.org) and Mark Adler(madler@alumni.caltech.edu)
 * and contributors of zlib.
 */

package com.wirelust.as3zlib {
import java.io.*;

public class ZInputStream extends FilterInputStream {

  protected var z:ZStream=new ZStream();
  protected var bufsize:int=512;
  protected var flush:int=JZlib.Z_NO_FLUSH;
  protected var buf:Array=new byte[bufsize],
                   buf1=new byte[1];
  protected var compress:Boolean;

  protected var in:InputStream=null;

  public function ZInputStream(in:InputStream) {
    this(in, false);
  }
  public function ZInputStream(in:InputStream, nowrap:Boolean) {
    super(in);
    this.in=in;
    z.inflateInit(nowrap);
    compress=false;
    z.next_in=buf;
    z.next_in_index=0;
    z.avail_in=0;
  }

  public function ZInputStream(in:InputStream, level:int) {
    super(in);
    this.in=in;
    z.deflateInit(level);
    compress=true;
    z.next_in=buf;
    z.next_in_index=0;
    z.avail_in=0;
  }

  /*public int available() throws IOException {
    return inf.finished() ? 0 : 1;
  }*/

  public function read():int throws IOException {
    if(read(buf1, 0, 1)==-1)
      return(-1);
    return(buf1[0]&0xFF);
  }

  private var nomoreinput:Boolean=false;

  public function read(b:Array, off:int, len:int):int throws IOException {
    if(len==0)
      return(0);
    var err:int;
    z.next_out=b;
    z.next_out_index=off;
    z.avail_out=len;
    do {
      if((z.avail_in==0)&&(!nomoreinput)) { // if buffer is empty and more input is avaiable, refill it
	z.next_in_index=0;
	z.avail_in=in.read(buf, 0, bufsize);//(bufsize<z.avail_out ? bufsize : z.avail_out));
	if(z.avail_in==-1) {
	  z.avail_in=0;
	  nomoreinput=true;
	}
      }
      if(compress)
	err=z.deflate(flush);
      else
	err=z.inflate(flush);
      if(nomoreinput&&(err==JZlib.Z_BUF_ERROR))
        return(-1);
      if(err!=JZlib.Z_OK && err!=JZlib.Z_STREAM_END)
	throw new ZStreamException((compress ? "de" : "in")+"flating: "+z.msg);
      if((nomoreinput||err==JZlib.Z_STREAM_END)&&(z.avail_out==len))
	return(-1);
    } 
    while(z.avail_out==len&&err==JZlib.Z_OK);
    //System.err.print("("+(len-z.avail_out)+")");
    return(len-z.avail_out);
  }

  public function skip(n:Number):Number throws IOException {
    var len:int=512;
    if(n<len)
      len=int(n);
    var tmp:Array=new byte[len];
    return(long(read(tmp)));
  }

  public function getFlushMode():int {
    return(flush);
  }

  public function setFlushMode(flush:int):void {
    this.flush=flush;
  }

  /**
   * Returns the total number of bytes input so far.
   */
  public function getTotalIn():Number {
    return z.total_in;
  }

  /**
   * Returns the total number of bytes output so far.
   */
  public function getTotalOut():Number {
    return z.total_out;
  }

  public function close():void throws IOException{
    in.close();
  }
}
}