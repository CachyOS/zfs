dnl # SPDX-License-Identifier: CDDL-1.0
AC_DEFUN([ZFS_AC_KERNEL_SRC_CREATE], [
	dnl #
	dnl # 7.3 API change.
	dnl #
	dnl # inode_operations->create drops the flag arg.  We test for the
	dnl # mnt_idmap version without the flag arg, to avoid having to test
	dnl # for all the idmap/userns variants back to before 5.12.
	dnl #
	ZFS_LINUX_TEST_SRC([create_no_flag], [
		#include <linux/fs.h>

		static int inode_create(struct mnt_idmap *idmap,
		    struct inode *inode, struct dentry *dentry,
		    umode_t mode) { return 0; }

		static const struct inode_operations
		    iops __attribute__ ((unused)) = {
			.create = inode_create,
		};
	],[])

	dnl #
	dnl # 6.3 API change
	dnl # The first arg is changed to struct mnt_idmap *
	dnl #
	ZFS_LINUX_TEST_SRC([create_mnt_idmap], [
		#include <linux/fs.h>
		#include <linux/sched.h>

		static int inode_create(struct mnt_idmap *idmap,
		    struct inode *inode ,struct dentry *dentry,
		    umode_t umode, bool flag) { return 0; }

		static const struct inode_operations
			iops __attribute__ ((unused)) = {
			.create         = inode_create,
		};
	],[])

	dnl #
	dnl # 5.12 API change that added the struct user_namespace* arg
	dnl # to the front of this function type's arg list.
	dnl #
	ZFS_LINUX_TEST_SRC([create_userns], [
		#include <linux/fs.h>
		#include <linux/sched.h>

		static int inode_create(struct user_namespace *userns,
		    struct inode *inode ,struct dentry *dentry,
		    umode_t umode, bool flag) { return 0; }

		static const struct inode_operations
			iops __attribute__ ((unused)) = {
			.create		= inode_create,
		};
	],[])

	dnl #
	dnl # 3.6 API change
	dnl #
	ZFS_LINUX_TEST_SRC([create_flags], [
		#include <linux/fs.h>
		#include <linux/sched.h>

		static int inode_create(struct inode *inode ,struct dentry *dentry,
		    umode_t umode, bool flag) { return 0; }

		static const struct inode_operations
		    iops __attribute__ ((unused)) = {
			.create		= inode_create,
		};
	],[])
])

AC_DEFUN([ZFS_AC_KERNEL_CREATE], [
	AC_MSG_CHECKING([whether iops->create() takes a flag arg])
	ZFS_LINUX_TEST_RESULT([create_no_flag], [
		AC_MSG_RESULT(no)
		AC_DEFINE(HAVE_IOPS_CREATE_NO_FLAG_ARG, 1,
		   [iops->create() does not take a flag arg])
		dnl #
		dnl # The test above is written against the mnt_idmap
		dnl # variant, so such kernels pass a struct mnt_idmap * as
		dnl # the first arg too.  Unlike upstream, this branch still
		dnl # keys all idmapped mount support off
		dnl # HAVE_IOPS_CREATE_IDMAP (see spl/sys/types.h), so it
		dnl # must be defined here as well.
		dnl #
		AC_DEFINE(HAVE_IOPS_CREATE_IDMAP, 1,
		   [iops->create() takes struct mnt_idmap*])
	],[
		AC_MSG_RESULT(yes)

		AC_MSG_CHECKING([whether iops->create() takes struct mnt_idmap*])
		ZFS_LINUX_TEST_RESULT([create_mnt_idmap], [
			AC_MSG_RESULT(yes)
			AC_DEFINE(HAVE_IOPS_CREATE_IDMAP, 1,
			   [iops->create() takes struct mnt_idmap*])
		],[
			AC_MSG_RESULT(no)

			AC_MSG_CHECKING([whether iops->create() takes struct user_namespace*])
			ZFS_LINUX_TEST_RESULT([create_userns], [
				AC_MSG_RESULT(yes)
				AC_DEFINE(HAVE_IOPS_CREATE_USERNS, 1,
				   [iops->create() takes struct user_namespace*])
			],[
				AC_MSG_RESULT(no)

				AC_MSG_CHECKING([whether iops->create() passes flags])
				ZFS_LINUX_TEST_RESULT([create_flags], [
					AC_MSG_RESULT(yes)
				],[
					ZFS_LINUX_TEST_ERROR([iops->create()])
				])
			])
		])
	])
])
