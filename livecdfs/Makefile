# $Id: Makefile,v 1.3 2004/01/18 17:52:03 jaco Exp $

include Rules.mk

all: $(LIBRARY) test

$(LIBRARY): $(OBJECTS)
	$(CC) -shared -Wl,-soname -Wl,$(LIBRARY).0.0 -o $(LIBRARY).0.0.0 $(OBJECTS)
	$(LN) -sf $(LIBRARY).0.0.0 $(LIBRARY).0.0
	$(LN) -sf $(LIBRARY).0.0.0 $(LIBRARY)

test: $(SRCDIR)/test.o $(OBJECTS) $(LUFSOBJS)  
	$(CXX) -o $@ $< $(OBJECTS) $(LUFSOBJS) 

install:
	$(MKDIR) -p $(DESTDIR)/$(LIBDIR)
	$(CP) -a $(LIBRARY)* $(DESTDIR)/$(LIBDIR)
	
.cpp.o:
	$(CXX) $(CXXFLAGS) -c -o $@ $<

.c.o:
	$(CC) $(CFLAGS) -c -o $@ $<
	
clean:
	$(RM) -rf $(SRCDIR)/*.o
	$(RM) -rf $(LIBRARY)* test
	$(FIND) $(LUFSDIR) -type f | $(GREP) .o$$ | $(XARGS) $(RM) -rf
	$(FIND) $(TOPDIR) -type f | $(GREP) ~$$ | $(XARGS) $(RM) -rf