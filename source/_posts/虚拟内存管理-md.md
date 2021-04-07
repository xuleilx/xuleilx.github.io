---
title: 虚拟内存管理
date: 2020-10-29 22:50:10
tags: 操作系统
categories:
 - 操作系统
---

# 虚拟内存管理
## 虚拟内存
### 虚拟内存的起因
| 存储器层次结构       | 访问时间    |
| ------------- | ------- |
| Registers     | 1 nsec  |
| Cache         | 2 nsec  |
| Main Memory   | 10 nsec |
| Magnetic disk | 10 msec |
| Magnetic tape | 100 sec |

### 覆盖技术
覆盖技术：相互之间没有调用关系的程序模块之间。

1.对于一个进程，不需要一开始就把程序的全部指令和数据都装入内存再执行。
2.程序划分为若干个功能上相对独立的程序段，按照程序逻辑结构让那些**不需要同时执行**的程序段共享同一块内存区
3.当有关程序段的先头程序段已经执行结束后，再把后续程序段从外存调入内存覆盖前面的程序段

![img](https://xuleilx.github.io/images/覆盖技术.png)

### 交换技术
swap技术：swap out、swap in。内存和硬盘之间。

对象是进程，等待状态的进程驻留内存会造成存储空间的浪费。因此，有必要把处于等待状态的进程换出内存。

### 虚存技术
利用程序的局部性。一页4K大小。
基本特征：
1.大的用户空间：物理内存+外存
2.部分交换
3.不连续性：分配不连续，使用不连续

后备存储Backing Store（二级存储）
数据，代码，动态库
swap file ：程序运行过程中产生的数据

##  页面置换算法
### 局部页面置换
1. 最优置换算法（OPT）：预测未来，难以实现
2. 先进先出（FIFO）：最简单，性能差
3. 最近最久未使用（LRU）：由过去预测未来，接近OPT，开销大。
4. 时钟算法（Clock）：性能接近LRU，高效，开销小
5. 二次机会法（Enhanced Clock）：Clock算法的改进，增加读写位判断，减少写页被置换
6. 最不常用算法（LFU）

**Belady现象：**
一些算法会导致导致不会因为物理页增加，内存访问减少。有时候反而增加内存访问。一般来讲，物理页增加，访问内存的次数会减少，极限情况物理页包含了所有内存。

### 全局页面置换
1. 工作集置换算法
2. 缺页率置换算法

针对多个程序同时运行，全局页面置换算法优于局部页面置换算法，全局页面置换算法可以动态调整分配给每个程序内存页的大小

**内存抖动**
1. 进程太多，分配给每个进程的物理页面太少，不能包含工作集
2. 造成大量缺页，频繁置换
3. 进程运行速度变慢

操作系统需要在并发水平和缺页率之间达到一个平衡

选择适当的程序数目和进程需要的物理页数目

![img](https://xuleilx.github.io/images/timg.jpg)

## LAB3实验
```C
// 给未被映射的地址映射上物理页
/*LAB3 EXERCISE 1: YOUR CODE
 * Maybe you want help comment, BELOW comments can help you finish the code
 *
 * Some Useful MACROs and DEFINEs, you can use them in below implementation.
 * MACROs or Functions:
 *   get_pte : get an pte and return the kernel virtual address of this pte for la
 *             if the PT contians this pte didn't exist, alloc a page for PT (notice the 3th parameter '1')
 *   pgdir_alloc_page : call alloc_page & page_insert functions to allocate a page size memory & setup
 *             an addr map pa<--->la with linear address la and the PDT pgdir
 * DEFINES:
 *   VM_WRITE  : If vma->vm_flags & VM_WRITE == 1/0, then the vma is writable/non writable
 *   PTE_W           0x002                   // page table/directory entry flags bit : Writeable
 *   PTE_U           0x004                   // page table/directory entry flags bit : User can access
 * VARIABLES:
 *   mm->pgdir : the PDT of these vma
 *
 */
/*
 * try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
 * (notice the 3th parameter '1')
 */
// 1. 页目录中找页表，如果没有就创建一个页表
// 2. 页表中查找包含addr地址的页表项
if ( (ptep = get_pte( mm->pgdir, addr, 1 ) ) == NULL )
{
	cprintf( "get_pte in do_pgfault failed\n" );
	goto failed;
}
// 如果找到的页表项为空，分配页并映射到页表中
if ( *ptep == 0 )     /* if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr */
{
	if ( pgdir_alloc_page( mm->pgdir, addr, perm ) == NULL )
	{
		cprintf( "pgdir_alloc_page in do_pgfault failed\n" );
		goto failed;
	}
}else  {
    // 找到页表项
	/*LAB3 EXERCISE 2: YOUR CODE
	 * Now we think this pte is a  swap entry, we should load data from disk to a page with phy addr,
	 * and map the phy addr with logical addr, trigger swap manager to record the access situation of this page.
	 *
	 *  Some Useful MACROs and DEFINEs, you can use them in below implementation.
	 *  MACROs or Functions:
	 *    swap_in(mm, addr, &page) : alloc a memory page, then according to the swap entry in PTE for addr,
	 *                               find the addr of disk page, read the content of disk page into this memroy page
	 *    page_insert ： build the map of phy addr of an Page with the linear addr la
	 *    swap_map_swappable ： set the page swappable
	 */
	/*
	 * if this pte is a swap entry, then load data from disk to a page with phy addr
	 * and call page_insert to map the phy addr with logical addr
	 */
    // 如果找到的页表项是需要swap的，swap it
	if ( swap_init_ok )
	{
		struct Page *page = NULL;
		if ( (ret = swap_in( mm, addr, &page ) ) != 0 )
		{
			cprintf( "swap_in in do_pgfault failed\n" );
			goto failed;
		}
		page_insert( mm->pgdir, page, addr, perm );
		swap_map_swappable( mm, addr, page, 1 );
	}else  {
		cprintf( "no swap_init_ok but ptep is %x, failed\n", *ptep );
		goto failed;
	}
}
```
```C
// 基于FIFO的页面替换算法
/*
 * (3)_fifo_map_swappable: According FIFO PRA, we should link the most recent arrival page at the back of pra_list_head qeueue
 */
static int
_fifo_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    list_entry_t *entry=&(page->pra_page_link);
 
    assert(entry != NULL && head != NULL);
    //record the page access situlation
    /*LAB3 EXERCISE 2: YOUR CODE*/ 
    //(1)link the most recent arrival page at the back of the pra_list_head qeueue.
    list_add(head, entry);
    return 0;
}
/*
 *  (4)_fifo_swap_out_victim: According FIFO PRA, we should unlink the  earliest arrival page in front of pra_list_head qeueue,
 *                            then set the addr of addr of this page to ptr_page.
 */
static int
_fifo_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
         assert(head != NULL);
     assert(in_tick==0);
     /* Select the victim */
     /*LAB3 EXERCISE 2: YOUR CODE*/ 
     //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
     //(2)  set the addr of addr of this page to ptr_page
     /* Select the tail */
     list_entry_t *le = head->prev;
     assert(head!=le);
     struct Page *p = le2page(le, pra_page_link);
     list_del(le);
     assert(p !=NULL);
     *ptr_page = p;
     return 0;
}
```
