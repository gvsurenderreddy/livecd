/*
 * LiveCD UnionFS implementation
 * Copyright (C) 2004, Jaco Greeff <jaco@linuxminicd.org>
 *
 *    This program is free software; you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation; either version 2 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * The latest version of this file can be found at http://livecd.berlios.de
 *
 * $Id: path.cpp,v 1.16 2004/02/02 04:58:23 jaco Exp $
 */

#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include <string> 

#include "path.h"

#include "debug.h"

Path *
Path::create(const string &root, 
	     const string &tmp)
{
	FUNC_START("root='%s', tmp='%s'", root.c_str(), tmp.c_str());
	     
	if (!exists(tmp, S_IFDIR)) {
		ERROR("FATAL: The path specified by 'rw_tmp='%s' does not exist as a directory.", tmp.c_str());
		FUNC_RET("%p", NULL, NULL);
	}
	
	Path *path = new Path(root, tmp);
	FUNC_RET("%p", path, path);
}


Path::Path(const string &root, 
	   const string &tmp)
{
	FUNC_START("root='%s', tmp='%s'", root.c_str(), tmp.c_str());
	     
	this->root = root;
	this->tmp = tmp;
	FUNC_END();
}


Path::~Path()
{
	FUNC_START("~destructor");
	FUNC_END();
}


string
Path::mkpath(const string &path)
{
	FUNC_START("path='%s'", path.c_str());
	
	string retpath = mktmp(path);
	if (!exists(retpath, 0)) {
		retpath = mkroot(path);
	}
	FUNC_RET("'%s'", retpath.c_str(), retpath);
}


bool
Path::copyTmp(const string &path)
{
	FUNC_START("path='%s'", path.c_str());
	
	string dir = getDir(path);
	if ((dir.length() != 0) && !isTmp(dir)) {
		TRACE("Creating directory dir='%s'", dir.c_str());
		recurseMkdir(dir); 
	}
	
	bool ret = false;
	struct stat buf;
	string rootpath = mkroot(path);
	
	if (stat(rootpath.c_str(), &buf) == 0) {
		string tmppath = mktmp(path);
		int dst = open(tmppath.c_str(), O_WRONLY | O_CREAT | O_TRUNC, buf.st_mode);
		if (dst > 0) {
			int src = open(rootpath.c_str(), O_RDONLY);
			if (src > 0) {
				char buf[8192];
				int len;
				int rtot = 0, wtot = 0;
				while ((len = read(src, &buf, 8192))) {
					rtot += len;
					wtot += write(dst, &buf, len);
				}
				close(src);
				ret = true;
				TRACE("Read %u bytes, wrote %u bytes", rtot, wtot);
			}
			else {
				WARN("Unable to open file='%s'", rootpath.c_str());
			}
			close(dst);
			chown(tmppath.c_str(), buf.st_uid, buf.st_gid);
		}
		else {
			WARN("Unable to open file='%s'", tmppath.c_str());
		}
	}
	
	FUNC_RET("%i", ret, ret);
}


string
Path::join(const string &s1, 
	   const string &s2)
{
	FUNC_START("s1='%s', s2='%s'", s1.c_str(), s2.c_str());
	 
	size_t len1 = s1.length();
	while (len1 && s1[len1 - 1] == '/') {
		--len1;
	}
	 
	string ret = string("");   
	if (s2.length() == 0 || s2 == string(".")) {
		ret = string(s1.c_str(), len1) + string("/");
	}
	else {
		size_t pos2 = 0;
		while ((pos2 < s2.length()) && s2[pos2] == '/') {
			pos2++;
		}
		ret = string(s1.c_str(), len1) + string("/") + string(s2.c_str(), pos2, s2.length());
	}
	FUNC_RET("'%s'", ret.c_str(), ret);
}


bool 
Path::exists(const string &path, 
	     int flags = 0)
{
	FUNC_START("path='%s', flags=%d", path.c_str(), flags);
	
	struct stat buf;
	if (lstat(path.c_str(), &buf) == 0) {
		TRACE("buf.st_mode=%u", buf.st_mode);
		if ((buf.st_mode & flags) == (unsigned int)flags) {
			FUNC_RET("%i", true, true);
		}
	}
	else {
		ERROR("strerror(errno)='%s' on lstat('%s', &buf)", strerror(errno), path.c_str());
	}
	
	FUNC_RET("%i", false, false);
}


bool 
Path::isDir(const string &path)
{
	FUNC_START("path='%s'", path.c_str());
	
	string full = mkpath(path);
	if (!exists(full, S_IFDIR)) {
		if (!exists(full, S_IFLNK)) {
			WARN("path='%s' is not a directory", path.c_str());
			FUNC_RET("%i", false, false);
		}
		
		char buf[2048];
		int num = readlink(full.c_str(), buf, 2048);
		if (num < 0) {
			WARN("path='%s' is not a directory", path.c_str());
			FUNC_RET("%i", false, false);
		}
		buf[num] = '\0';
		string link = mkpath(buf);
		if (!exists(link, S_IFDIR)) {
			WARN("path='%s' is not a directory", path.c_str());
			FUNC_RET("%i", false, false);
		}
		TRACE("path='%s' is a directory (link)", path.c_str());
	}
	FUNC_RET("%i", true, true);
}


string
Path::getDir(const string &path) 
{
	FUNC_START("path='%s'", path.c_str());
	
	string dir = join("/", path);
	if (!isDir(path)) {
		int pos = path.rfind("/");
		if (pos >= 0) {
			dir = string(path, 0, pos);
		}
		else {
			dir = string("");
		}
	}
	FUNC_RET("'%s'", dir.c_str(), dir);
}


void
Path::recurseMkdir(const string &path,
		   const string &root) 
{
	FUNC_START("path='%s', root='%s'", path.c_str(), root.c_str());
	
	if (exists(mktmp(join(root, path)), 0)) {
		TRACE("Already existing (tmp) root='%s', path='%s'", root.c_str(), path.c_str());
		FUNC_END();
	}
	
	struct stat buf;
	if (!exists(mktmp(root), 0)) {
		TRACE("Making root='%s'", root.c_str());
		int mode = 0777;
		int uid = 0;
		int gid = 0;
		if (stat(mkroot(root).c_str(), &buf) == 0) {
			mode = buf.st_mode;
			uid = buf.st_uid;
			gid = buf.st_gid;
		}
		if (mkdir(mktmp(root).c_str(), mode) != 0) {
			ERROR("Creation of root='%s' failed", root.c_str());
			FUNC_END();
		}
		chown(mktmp(root).c_str(), uid, gid);
	}
	else {
		TRACE("Already existing (tmp) root='%s'", root.c_str());
	}
	
	int pos = path.find("/", 1);
	if (pos > 0) {
		string newpath = path.substr(pos);
		string newroot = join(root, path.substr(0, pos));
		TRACE("Recursing path='%s', root='%s'", newpath.c_str(), newroot.c_str());
		recurseMkdir(newpath, newroot);
	}
	else {
		string dir = join(root, path);
		TRACE("Making dir='%s'", dir.c_str());
		int mode = 0777;
		int uid = 0;
		int gid = 0;
		if (stat(mkroot(dir).c_str(), &buf) == 0) {
			mode = buf.st_mode;
			uid = buf.st_uid;
			gid = buf.st_gid;
		}
		mkdir(mktmp(dir).c_str(), mode);
		chown(mktmp(dir).c_str(), uid, gid);
	}
	
	TRACE("Recurse path='%s', root='%s' completed", path.c_str(), root.c_str());
	FUNC_END();
}
