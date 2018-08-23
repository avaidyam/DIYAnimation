// Copyright (c) 2009-2011 Apple Inc. All rights reserved.

#ifndef __XPC_PRIVATE_H__
#define __XPC_PRIVATE_H__
#ifndef __XPC_INDIRECT__
#define __XPC_INDIRECT__
#endif // __XPC_INDIRECT__
#include <xpc/base.h>
XPC_ASSUME_NONNULL_BEGIN
__BEGIN_DECLS

#pragma mark XPC Types
/*!
 * @define XPC_TYPE_MACH_SEND
 * A type representing a mach send right value.
 */
#define XPC_TYPE_MACH_SEND (&_xpc_type_mach_send)
__OSX_AVAILABLE_STARTING(__MAC_10_7, __IPHONE_5_0)
XPC_EXPORT
XPC_TYPE(_xpc_type_mach_send);

/*!
 * @define XPC_TYPE_MACH_RECV
 * A type representing a mach receive right value.
 */
#define XPC_TYPE_MACH_RECV (&_xpc_type_mach_recv)
__OSX_AVAILABLE_STARTING(__MAC_10_7, __IPHONE_5_0)
XPC_EXPORT
XPC_TYPE(_xpc_type_mach_recv);

/*!
 * @define XPC_TYPE_POINTER
 * A type representing a pointer value.
 */
#define XPC_TYPE_POINTER (&_xpc_type_pointer)
__OSX_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0)
XPC_EXPORT
XPC_TYPE(_xpc_type_pointer);

/*!
 * @define XPC_TYPE_PIPE
 * A type representing a pipe to a resource. This pipe is unidirectional and can
 * only be used to send messages from one end, and receive them on the other. A
 * pipe carries the credentials of the remote service provider.
 *
 * Of the MIG calls, only routines and simpleroutines are supported. Functions
 * and procedures (including simpleprocedures) are not supported by pipe objects.
 */
#define XPC_TYPE_PIPE (&_xpc_type_pipe)
__OSX_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0)
XPC_EXPORT
XPC_TYPE(_xpc_type_pipe);
XPC_DECL(xpc_pipe);

#undef __XPC_INDIRECT__

#pragma mark Audit Tokens
/*!
 * @function xpc_dictionary_get_audit_token
 *
 * @abstract
 * Returns the BSM audit token of the sender of the dictionary object.
 *
 * @param xdict
 * The dictionary object which is to be examined.
 *
 * @param token
 * A pointer which is to be filled with the BSM audit token of the sender.
 * May not be NULL. If the dictionary does not contain an audit token, the
 * value at this pointer will be set to 0.
 */
XPC_EXPORT XPC_NONNULL_ALL
void
xpc_dictionary_get_audit_token(xpc_object_t xdict, audit_token_t *token);

#pragma mark Expect Reply
/*!
 * @function xpc_dictionary_expects_reply
 *
 * @abstract
 * Returns whether a reply is requested by the sender of the dictionary object.
 *
 * @param xdict
 * The dictionary object which is to be examined.
 *
 * @result
 * Whether the dictionary object is a request whose sender expects a reply object.
 */
XPC_EXPORT XPC_NONNULL_ALL
boolean_t
xpc_dictionary_expects_reply(xpc_object_t xdict);

#pragma mark Mach Send
/*!
 * @function xpc_mach_send_create
 *
 * @abstract
 * Creates an XPC mach send right object.
 *
 * @param value
 * The mach port value containing the mach send right which is to be boxed.
 *
 * @result
 * A new mach send right object.
 */
__OSX_AVAILABLE_STARTING(__MAC_10_7, __IPHONE_5_0)
XPC_EXPORT XPC_MALLOC XPC_RETURNS_RETAINED XPC_WARN_RESULT
xpc_object_t
xpc_mach_send_create(mach_port_t value);

/*!
 * @function xpc_mach_send_get_right
 *
 * @abstract
 * Returns the underlying mach port value containing a send right from an object.
 *
 * @param xsend
 * The mach send right object which is to be examined.
 *
 * @result
 * The underlying mach port value containing the send right or `MACH_PORT_NULL`
 * if the given object was not an XPC mach send right object.
 */
XPC_EXPORT XPC_NONNULL_ALL
mach_port_t
xpc_mach_send_get_right(xpc_object_t xsend);

/*!
 * @function xpc_mach_send_copy_right
 *
 * @abstract
 * Returns a mach port value containing a copy of the send right from an object.
 *
 * @param xsend
 * The mach send right object which is to be examined.
 *
 * @result
 * A mach port value containing a copy of the underlying send right or `MACH_PORT_NULL`
 * if the given object was not an XPC mach send right object.
 */
XPC_EXPORT XPC_NONNULL_ALL
mach_port_t
xpc_mach_send_copy_right(xpc_object_t xsend);

/*!
 * @function xpc_dictionary_set_mach_send
 *
 * @abstract
 * Inserts a mach send right value into a dictionary.
 *
 * @param xdict
 * The dictionary which is to be manipulated.
 *
 * @param key
 * The key for which the primitive value shall be set.
 *
 * @param value
 * The mach send right value to insert. After calling this method, the XPC
 * object corresponding to the primitive value inserted may be safely retrieved
 * with {@link xpc_dictionary_get_value()}.
 */
XPC_EXPORT XPC_NONNULL1 XPC_NONNULL2
void
xpc_dictionary_set_mach_send(xpc_object_t xdict, const char *key, mach_port_t value);

/*!
 * @function xpc_dictionary_copy_mach_send
 *
 * @abstract
 * Copies a mach send right value from a dictionary directly.
 *
 * @param xdict
 * The dictionary object which is to be examined.
 *
 * @param key
 * The key whose value is to be obtained.
 *
 * @result
 * The underlying mach send right value for the specified key. `MACH_PORT_NULL`
 * if the value for the specified key is not a mach send right value or if there
 * is no value for the specified key.
 */
XPC_EXPORT XPC_NONNULL_ALL
mach_port_t
xpc_dictionary_copy_mach_send(xpc_object_t xdict, const char *key);

/*!
 * @function xpc_array_set_mach_send
 *
 * @abstract
 * Inserts a mach send right value into an array.
 *
 * @param xarray
 * The array object which is to be manipulated.
 *
 * @param index
 * The index at which to insert the value. This value must lie within the index
 * space of the array (0 to N-1 inclusive, where N is the count of the array) or
 * be XPC_ARRAY_APPEND. If the index is outside that range, the behavior is
 * undefined.
 *
 * @param value
 * The mach send right value to insert. After calling this method, the XPC
 * object corresponding to the primitive value inserted may be safely retrieved
 * with {@link xpc_array_get_value()}.
 */
XPC_EXPORT XPC_NONNULL1
void
xpc_array_set_mach_send(xpc_object_t xarray, size_t index, mach_port_t value);

/*!
 * @function xpc_array_copy_mach_send
 *
 * @abstract
 * Copies a mach send right value from an array directly.
 *
 * @param xarray
 * The array which is to be examined.
 *
 * @param index
 * The index of the value to obtain. This value must lie within the index space
 * of the array (0 to N-1 inclusive, where N is the count of the array). If the
 * index is outside that range, the behavior is undefined.
 *
 * @result
 * The underlying mach send right value at the specified index. `MACH_PORT_NULL`
 * if the value at the specified index is not a mach send right value.
 */
XPC_EXPORT XPC_NONNULL1
mach_port_t
xpc_array_copy_mach_send(xpc_object_t xarray, size_t index);

#pragma mark Mach Receive
/*!
 * @function xpc_mach_recv_create
 *
 * @abstract
 * Creates an XPC mach receive right object.
 *
 * @param value
 * The mach port value containing the mach receive right which is to be boxed.
 *
 * @result
 * A new mach receive right object.
 */
__OSX_AVAILABLE_STARTING(__MAC_10_7, __IPHONE_5_0)
XPC_EXPORT XPC_MALLOC XPC_RETURNS_RETAINED XPC_WARN_RESULT
xpc_object_t
xpc_mach_recv_create(mach_port_t value);

/*!
 * @function xpc_mach_recv_extract_right
 *
 * @abstract
 * Returns the underlying mach port value containing a receive right from an object.
 *
 * @param xrecv
 * The mach receive right object which is to be examined.
 *
 * @result
 * The underlying mach port value containing the receive right or `MACH_PORT_NULL`
 * if the given object was not an XPC mach receive right object.
 */
XPC_EXPORT XPC_NONNULL_ALL
mach_port_t
xpc_mach_recv_extract_right(xpc_object_t xrecv);

/*!
 * @function xpc_dictionary_set_mach_recv
 *
 * @abstract
 * Inserts a mach receive right value into a dictionary.
 *
 * @param xdict
 * The dictionary which is to be manipulated.
 *
 * @param key
 * The key for which the primitive value shall be set.
 *
 * @param value
 * The mach receive right value to insert. After calling this method, the XPC
 * object corresponding to the primitive value inserted may be safely retrieved
 * with {@link xpc_dictionary_get_value()}.
 */
XPC_EXPORT XPC_NONNULL1 XPC_NONNULL2
void
xpc_dictionary_set_mach_recv(xpc_object_t xdict, const char *key, mach_port_t value);

/*!
 * @function xpc_dictionary_extract_mach_recv
 *
 * @abstract
 * Extracts a mach receive right value from a dictionary directly.
 *
 * @param xdict
 * The dictionary object which is to be examined.
 *
 * @param key
 * The key whose value is to be obtained.
 *
 * @result
 * The underlying mach receive right value for the specified key. `MACH_PORT_NULL`
 * if the value for the specified key is not a mach receive right value or if there
 * is no value for the specified key.
 */
XPC_EXPORT XPC_NONNULL_ALL
mach_port_t
xpc_dictionary_extract_mach_recv(xpc_object_t xdict, const char *key);

/*!
 * @function xpc_array_set_mach_recv
 *
 * @abstract
 * Inserts a mach receive right value into an array.
 *
 * @param xarray
 * The array object which is to be manipulated.
 *
 * @param index
 * The index at which to insert the value. This value must lie within the index
 * space of the array (0 to N-1 inclusive, where N is the count of the array) or
 * be XPC_ARRAY_APPEND. If the index is outside that range, the behavior is
 * undefined.
 *
 * @param value
 * The mach receive right value to insert. After calling this method, the XPC
 * object corresponding to the primitive value inserted may be safely retrieved
 * with {@link xpc_array_get_value()}.
 */
XPC_INLINE XPC_NONNULL1
void
xpc_array_set_mach_recv(xpc_object_t xarray, size_t index, mach_port_t value) {
    xpc_array_set_value(xarray, index, xpc_mach_recv_create(value));
}

/*!
 * @function xpc_array_extract_mach_recv
 *
 * @abstract
 * Extracts a mach receive right value from an array directly.
 *
 * @param xarray
 * The array which is to be examined.
 *
 * @param index
 * The index of the value to obtain. This value must lie within the index space
 * of the array (0 to N-1 inclusive, where N is the count of the array). If the
 * index is outside that range, the behavior is undefined.
 *
 * @result
 * The underlying mach receive right value at the specified index. `MACH_PORT_NULL`
 * if the value at the specified index is not a mach receive right value.
 */
XPC_INLINE XPC_NONNULL1
mach_port_t
xpc_array_extract_mach_recv(xpc_object_t xarray, size_t index) {
    return xpc_mach_recv_extract_right(xpc_array_get_value(xarray, index));
}

#pragma mark Pointer
/*!
 * @function xpc_pointer_create
 *
 * @abstract
 * Creates an XPC pointer object.
 *
 * @param value
 * The native pointer value which is to be boxed.
 *
 * @result
 * A new pointer object.
 */
__OSX_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0)
XPC_EXPORT XPC_MALLOC XPC_RETURNS_RETAINED XPC_WARN_RESULT
xpc_object_t
xpc_pointer_create(pointer_t value);

/*!
 * @function xpc_pointer_get_value
 *
 * @abstract
 * Returns the underlying native pointer value from an object.
 *
 * @param xpointer
 * The pointer object which is to be examined.
 *
 * @result
 * The underlying pointer value or `NULL` if the given object was not an XPC
 * pointer object.
 */
XPC_EXPORT
pointer_t
xpc_pointer_get_value(xpc_object_t xpointer);

/*!
 * @function xpc_dictionary_set_pointer
 *
 * @abstract
 * Inserts a <code>pointer_t</code> (primitive) value into a dictionary.
 *
 * @param xdict
 * The dictionary which is to be manipulated.
 *
 * @param key
 * The key for which the primitive value shall be set.
 *
 * @param value
 * The <code>pointer_t</code> value to insert. After calling this method, the XPC
 * object corresponding to the primitive value inserted may be safely retrieved
 * with {@link xpc_dictionary_get_value()}.
 */
XPC_EXPORT
void
xpc_dictionary_set_pointer(xpc_object_t xdict, const char *key, pointer_t value);

/*!
 * @function xpc_dictionary_get_pointer
 *
 * @abstract
 * Gets a <code>pointer_t</code> (primitive) value from a dictionary directly.
 *
 * @param xdict
 * The dictionary object which is to be examined.
 *
 * @param key
 * The key whose value is to be obtained.
 *
 * @result
 * The underlying <code>pointer_t</code> value for the specified key. `NULL`
 * if the value for the specified key is not a <code>pointer_t</code> value or if
 * there is no value for the specified key.
 */
XPC_EXPORT
pointer_t
xpc_dictionary_get_pointer(xpc_object_t xdict, const char *key);

/*!
 * @function xpc_array_set_pointer
 *
 * @abstract
 * Inserts a <code>pointer_t</code> (primitive) value into an array.
 *
 * @param xarray
 * The array object which is to be manipulated.
 *
 * @param index
 * The index at which to insert the value. This value must lie within the index
 * space of the array (0 to N-1 inclusive, where N is the count of the array) or
 * be XPC_ARRAY_APPEND. If the index is outside that range, the behavior is
 * undefined.
 *
 * @param value
 * The <code>pointer_t</code> value to insert. After calling this method, the XPC
 * object corresponding to the primitive value inserted may be safely retrieved
 * with {@link xpc_array_get_value()}.
 */
XPC_EXPORT
void
xpc_array_set_pointer(xpc_object_t xarray, size_t index, pointer_t value);

/*!
 * @function xpc_array_get_pointer
 *
 * @abstract
 * Gets a <code>pointer_t</code> (primitive) value from an array directly.
 *
 * @param xarray
 * The array which is to be examined.
 *
 * @param index
 * The index of the value to obtain. This value must lie within the index space
 * of the array (0 to N-1 inclusive, where N is the count of the array). If the
 * index is outside that range, the behavior is undefined.
 *
 * @result
 * The underlying <code>pointer_t</code> value at the specified index. `MACH_PORT_NULL`
 * if the value at the specified index is not a <code>pointer_t</code> value.
 */
XPC_EXPORT
pointer_t
xpc_array_get_pointer(xpc_object_t xarray, size_t index);

#pragma mark Pipe
/*!
 * @constant XPC_PIPE_FLAG_PRIVILEGED
 * Passed to xpc_pipe_create() or xpc_pipe_create_from_port().
 */
#define XPC_PIPE_FLAG_PRIVILEGED (1 << 5)

/*!
 * @typedef xpc_pipe_mig_call_f
 * Allow receivers of pipes to handle both XPC and MIG requests from
 * xpc_pipe_try_receive. If an MIG request is received, the handler matching
 * this function declaration is invoked.
 *
 * @param request
 * The MIG request object whose type and information is known by the caller.
 *
 * @param reply
 * The MIG reply object whose type and information is known by the caller.
 *
 * @param result
 * Whether the MIG routine was successfully handled by the demux handler.
 */
typedef boolean_t (*xpc_pipe_mig_call_t)(mach_msg_header_t *request, mach_msg_header_t *reply);

/*!
 * @function xpc_pipe_create
 *
 * @abstract
 * Create a pipe object to send messages to a mach port identified in the bootstrap
 * domain by a service name.
 *
 * @param name
 * The service name of a mach port in the bootstrap domain to connect to.
 *
 * @param flags
 * Can be any flags accepted by bootstrap_look_up2 as well as
 * XPC_PIPE_FLAG_PRIVILEGED.
 *
 * @result
 * A new pipe object.
 */
__OSX_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0)
XPC_EXPORT XPC_MALLOC XPC_RETURNS_RETAINED XPC_WARN_RESULT XPC_NONNULL1
xpc_pipe_t
xpc_pipe_create(const char *name, uint64_t flags);

/*!
 * @function xpc_pipe_create_from_port
 *
 * @abstract
 * Create a pipe object to send messages to a mach port.
 *
 * @param port
 * The mach port for which a send right is held by the owning task, that will
 * serve as the endpoint of the pipe being created.
 *
 * @param flags
 * Can be XPC_PIPE_FLAG_PRIVILEGED.
 *
 * @result
 * A new pipe object.
 */
__OSX_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0)
XPC_EXPORT XPC_MALLOC XPC_RETURNS_RETAINED XPC_WARN_RESULT
xpc_pipe_t
xpc_pipe_create_from_port(mach_port_t port, uint64_t flags);

/*!
 * @function xpc_pipe_invalidate
 *
 * @abstract
 * Invalidates the pipe and ensures that it may not be used to send further messages.
 * After this call, any messages that have not yet been sent will be discarded,
 * and the pipe will be unwound.
 *
 * @param pipe
 * The pipe object which is to be manipulated.
 */
__OSX_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0)
XPC_EXPORT XPC_NONNULL_ALL
void
xpc_pipe_invalidate(xpc_pipe_t pipe);

/*!
 * @function xpc_pipe_routine
 *
 * @abstract
 * Synchronously send a request to the endpoint of the pipe, awaiting a reply.
 *
 * @param pipe
 * The pipe object which is to be manipulated.
 *
 * @param request
 * The XPC dictionary to be sent as the request.
 *
 * @param reply
 * A pointer to be filled with the reply object. May be NULL.
 *
 * @result
 * The status of the operation. Either KERN_SUCCESS or an error code.
 */
__OSX_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0)
XPC_EXPORT XPC_NONNULL1 XPC_NONNULL2
kern_return_t
xpc_pipe_routine(xpc_pipe_t pipe, xpc_object_t request, xpc_object_t *reply);

/*!
 * @function xpc_pipe_simpleroutine
 *
 * @abstract
 * Synchronously sends a request to the endpoint of the pipe, without awaiting
 * a reply.
 *
 * @param pipe
 * The pipe object which is to be manipulated.
 *
 * @param request
 * The XPC dictionary to be sent as the request.
 *
 * @result
 * The status of the operation. Either KERN_SUCCESS or an error code.
 */
__OSX_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0)
XPC_EXPORT XPC_NONNULL_ALL
kern_return_t
xpc_pipe_simpleroutine(xpc_pipe_t pipe, xpc_object_t request);

/*!
 * @function xpc_pipe_routine_forward
 *
 * @abstract
 * Forwards a request received on one pipe to another pipe.
 *
 * @param forward_to
 * The new receiving pipe to which the request message shall be forwarded to.
 *
 * @param request
 * The request object to forward.
 *
 * @result
 * The status of the operation. Either KERN_SUCCESS or an error code.
 */
__OSX_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0)
XPC_EXPORT XPC_NONNULL_ALL
kern_return_t
xpc_pipe_routine_forward(xpc_pipe_t forward_to, xpc_object_t request);

/*!
 * @function xpc_pipe_routine_async
 *
 * @abstract
 * Asynchronously send a request to the endpoint of the pipe, awaiting a reply
 * object at the mach port provided.
 *
 * @param pipe
 * The pipe object which is to be manipulated.
 *
 * @param request
 * The XPC dictionary to be sent as the request.
 *
 * @param reply_port
 * The mach port on which both a send and receive right are held which shall
 * receive the reply object, if any.
 *
 * @result
 * The status of the operation. Either KERN_SUCCESS or an error code.
 */
__OSX_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0)
XPC_EXPORT XPC_NONNULL_ALL
kern_return_t
xpc_pipe_routine_async(xpc_pipe_t pipe, xpc_object_t request, mach_port_t reply_port);

/*!
 * @function xpc_pipe_receive
 *
 * @abstract
 * Awaits the receipt of a request object as the receiver of a pipe.
 *
 * @param port
 * The mach port to which a receive right is held that shall be awaited on.
 *
 * @param request
 * A pointer to be filled with the request object. May not be NULL.
 *
 * @result
 * The status of the operation. Either KERN_SUCCESS or an error code.
 *
 * @discussion
 * It is the receiver's responsibility to invoke xpc_pipe_routine_reply if needed.
 * To determine if this is the case, use xpc_dictionary_expects_reply.
 */
__OSX_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0)
XPC_EXPORT XPC_NONNULL_ALL
kern_return_t
xpc_pipe_receive(mach_port_t port, xpc_object_t *request);

/*!
 * @function xpc_pipe_routine_reply
 *
 * @abstract
 * Send a reply object in response to a request received as the receiver of a pipe
 * from xpc_pipe_receive or xpc_pipe_try_receive.
 *
 * @param reply
 * The XPC dictionary object created after a call to xpc_dictionary_create_reply.
 *
 * @result
 * The status of the operation. Either KERN_SUCCESS or an error code.
 */
__OSX_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0)
XPC_EXPORT XPC_NONNULL_ALL
kern_return_t
xpc_pipe_routine_reply(xpc_object_t reply);

/*!
 * @function xpc_pipe_try_receive
 *
 * @abstract
 * Awaits the receipt of a request XPC or MIG request object as the receiver of
 * a pipe.
 *
 * @param port
 * The mach port to which a receive right is held that shall be awaited on.
 *
 * @param request
 * A pointer to be filled with the XPC request object. May not be NULL.
 *
 * @param out_port
 * A pointer to be filled with the receiving mach port of the XPC object.
 *
 * @param mig_handler
 * An xpc_pipe_mig_call_t handler to intercept MIG objects. If a MIG
 * object is received, the request will set to be NULL.
 *
 * @param mig_size
 * The size of potential MIG request objects that may be received.
 *
 * @param flags
 * MIG request flags. Currently undefined, pass 0.
 *
 * @result
 * The status of the operation. Either KERN_SUCCESS or an error code.
 *
 * @discussion
 * This function is used internally by launchd. Use at your own risk.
 *
 * If the receiver of a pipe may need to handle legacy MIG calls alongside
 * XPC requests, use this function to do so. If a MIG call is received, only the
 * handler is invoked; no XPC request object is returned.
 *
 * It is the receiver's responsibility to invoke xpc_pipe_routine_reply if needed.
 * To determine if this is the case, use xpc_dictionary_expects_reply.
 */
__OSX_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0)
XPC_EXPORT XPC_NONNULL1 XPC_NONNULL2 XPC_NONNULL3 XPC_NONNULL4
kern_return_t
xpc_pipe_try_receive(mach_port_t *port, xpc_object_t *request, mach_port_t *out_port, xpc_pipe_mig_call_t mig_handler, mach_msg_size_t mig_size, uint64_t flags);

__END_DECLS
XPC_ASSUME_NONNULL_END
#endif /* __XPC_PRIVATE_H__ */
