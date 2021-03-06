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
 * $Id: main.cpp,v 1.6 2004/01/25 17:09:59 jaco Exp $
 */
 
#include <lufs/proto.h>
#include <lufs/fs.h>

#include "livecdfs.h"

#include "debug.h"

#ifdef DEBUG
int _debug = 0;
#endif

extern "C"{

void *
livecdfs_init(struct list_head *cfg, 
	      struct dir_cache *cache, 
	      struct credentials *cred, 
	      void **global_ctx)
{
	FUNC_START("cfg=%p, cache=%p, cred=%p, global_ctx=%p", cfg, cache, cred, global_ctx);
	void *fs = (void *)LiveCDFS::create(cfg, cache, cred);
	FUNC_RET("%p", fs, fs);
}


void 
livecdfs_free(void *fs)
{
	FUNC_START("fs=%p", fs);
	LiveCDFS::destroy((LiveCDFS*)fs);
	FUNC_END();
}


int 
livecdfs_mount(void *fs)
{
	FUNC_START("fs=%p", fs);
	int ret = ((LiveCDFS*)fs)->doMount();
	FUNC_RET("%d", ret, ret);
}


void 
livecdfs_umount(void *fs)
{
	FUNC_START("fs=%p", fs);
	((LiveCDFS*)fs)->doUmount();
	FUNC_END();
}


int 
livecdfs_readdir(void *fs, 
		 char *name, 
		 struct directory *dir)
{
	FUNC_START("fs=%p, name='%s', dir=%p", fs, name, dir);
	int ret = ((LiveCDFS*)fs)->doReaddir(name, dir);
	FUNC_RET("%d", ret, ret);
}


int 
livecdfs_stat(void *fs, 
	      char *name, 
	      struct lufs_fattr *attr)
{
	FUNC_START("fs=%p, name='%s', attr=%p", fs, name, attr);
	int ret = ((LiveCDFS*)fs)->doStat(name, attr);
	FUNC_RET("%d", ret, ret);
}


int 
livecdfs_mkdir(void *fs, 
	       char *dir, 
	       int mode)
{
	FUNC_START("fs=%p, dir='%s', mode=%u", fs, dir, mode);
	int ret = ((LiveCDFS*)fs)->doMkdir(dir, mode);
	FUNC_RET("%d", ret, ret);
}


int 
livecdfs_rmdir(void *fs, 
	       char *dir)
{
	FUNC_START("fs=%p, dir='%s'", fs, dir);
	int ret = ((LiveCDFS*)fs)->doRmdir(dir);
	FUNC_RET("%d", ret, ret);
}


int 
livecdfs_create(void *fs, 
		char *file, 
		int mode)
{
	FUNC_START("fs=%p, file='%s', mode=%u", fs, file, mode);
	int ret = ((LiveCDFS*)fs)->doCreate(file, mode);
	FUNC_RET("%d", ret, ret);
}


int 
livecdfs_unlink(void *fs, 
		char *file)
{
	FUNC_START("fs=%p, file='%s'", fs, file);
	int ret = ((LiveCDFS*)fs)->doUnlink(file);
	FUNC_RET("%d", ret, ret);
}


int 
livecdfs_rename(void *fs, 
		char *oldname, 
		char *newname)
{
	FUNC_START("fs=%p, old='%s', new='%s'", fs, oldname, newname);
	int ret = ((LiveCDFS*)fs)->doRename(oldname, newname);
	FUNC_RET("%d", ret, ret);
}


int 
livecdfs_open(void *fs, 
	      char *file, 
	      unsigned mode)
{
	FUNC_START("fs=%p, file='%s', mode=%u", fs, file, mode);
	int ret = ((LiveCDFS*)fs)->doOpen(file, mode);
	FUNC_RET("%d", ret, ret);
}


int 
livecdfs_release(void *fs, 
		 char *file)
{
	FUNC_START("fs=%p, file='%s'", fs, file);
	int ret = ((LiveCDFS*)fs)->doRelease(file);
	FUNC_RET("%d", ret, ret);
}


int 
livecdfs_read(void *fs, 
	      char *file, 
	      long long offset, 
	      unsigned long count, 
	      char *buf)
{
	FUNC_START("fs=%p, file='%s', offset=%l, count=%ul, buf=%p", fs, file, offset, count, buf);
	int ret = ((LiveCDFS*)fs)->doRead(file, offset, count, buf);
	FUNC_RET("%d", ret, ret);
}


int 
livecdfs_write(void *fs, 
	       char *file, 
	       long long offset, 
	       unsigned long count, 
	       char *buf)
{
	FUNC_START("fs=%p, file='%s', offset=%l, count=%ul, buf=%p", fs, file, offset, count, buf);
	int ret = ((LiveCDFS*)fs)->doWrite(file, offset, count, buf);
	FUNC_RET("%d", ret, ret);
}


int 
livecdfs_readlink(void *fs, 
		  char *link, 
		  char *buf, 
		  int buflen)
{
	FUNC_START("fs=%p, link='%s', buf=%p, buflen=%u", fs, link, buf, buflen);
	int ret = ((LiveCDFS*)fs)->doReadlink(link, buf, buflen);
	FUNC_RET("%d", ret, ret);
}


int 
livecdfs_link(void *fs, 
	      char *target, 
	      char *link)
{
	FUNC_START("fs=%p, target='%s', link='%s'", fs, target, link);
	int ret = ((LiveCDFS*)fs)->doLink(target, link);
	FUNC_RET("%d", ret, ret);
}


int 
livecdfs_symlink(void *fs, 
		 char *target, 
		 char *link)
{
	FUNC_START("fs=%p, target='%s', link='%s'", fs, target, link);
	int ret = ((LiveCDFS*)fs)->doSymlink(target, link);
	FUNC_RET("%d", ret, ret);
}


int 
livecdfs_setattr(void *fs, 
		 char *file, 
		 struct lufs_fattr *attr)
{
	FUNC_START("fs=%p, file='%s', attr=%p", fs, file, attr);
	int ret = ((LiveCDFS*)fs)->doSetattr(file, attr);
	FUNC_RET("%d", ret, ret);
}

}
