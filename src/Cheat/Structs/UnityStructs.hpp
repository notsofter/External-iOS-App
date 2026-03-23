#pragma once

#include <stddef.h>

#include "../Memory/Memory.h"
#include "Quaternion.hpp"

static void *safe_malloc(size_t size) {
    if (size > 0x1000)
        return NULL;

    return malloc(size);
}

static char *utf16_to_utf8(const char *utf16, int length) {
    char *utf8 = (char*)safe_malloc(length);
    bzero(utf8, length);

    int utf8_index = 0;
    int i = 0;

    while (i < length) {
        uint16_t code_unit = (uint16_t)((utf16[i+1] << 8) | utf16[i]);
        i += 2;

        if (code_unit < 0x80) {
            utf8[utf8_index++] = (char)code_unit;
        } else if (code_unit < 0x800) {
            utf8[utf8_index++] = (char)((code_unit >> 6) | 0xC0);
            utf8[utf8_index++] = (char)((code_unit & 0x3F) | 0x80);
        } else if (code_unit >= 0xD800 && code_unit <= 0xDBFF) {
            if (i < length) {
                uint16_t high_surrogate = code_unit;
                uint16_t low_surrogate = (uint16_t)((utf16[i+1] << 8) | utf16[i]);
                i += 2;
                uint32_t full_code_point = 0x10000 + (((high_surrogate & 0x3FF) << 10) | (low_surrogate & 0x3FF));

                utf8[utf8_index++] = (char)((full_code_point >> 18) | 0xF0);
                utf8[utf8_index++] = (char)(((full_code_point >> 12) & 0x3F) | 0x80);
                utf8[utf8_index++] = (char)(((full_code_point >> 6) & 0x3F) | 0x80);
                utf8[utf8_index++] = (char)((full_code_point & 0x3F) | 0x80);
            }
        } else {
            utf8[utf8_index++] = (char)((code_unit >> 12) | 0xE0);
            utf8[utf8_index++] = (char)(((code_unit >> 6) & 0x3F) | 0x80);
            utf8[utf8_index++] = (char)((code_unit & 0x3F) | 0x80);
        }
    }

    utf8[utf8_index] = '\0';

    return utf8;
}

namespace StringUtils {
    static void utf16_to_utf8(uint8_t *utf8_buffer, size_t utf8_string_len, uint16_t *utf16_string, size_t utf16_string_len)
    {
        uint16_t *pTempUTF16 = utf16_string;
        uint8_t *pTempUTF8 = utf8_buffer;
        uint8_t *pUTF8End = pTempUTF8 + utf8_string_len;
        while (pTempUTF16 < pTempUTF16 + utf16_string_len)
        {
            if (*pTempUTF16 <= 0x007F && pTempUTF8 + 1 < pUTF8End)
            {
                *pTempUTF8++ = (uint8_t)*pTempUTF16;
            }
            else if (*pTempUTF16 >= 0x0080 && *pTempUTF16 <= 0x07FF && pTempUTF8 + 2 < pUTF8End)
            {
                *pTempUTF8++ = (*pTempUTF16 >> 6) | 0xC0;
                *pTempUTF8++ = (*pTempUTF16 & 0x3F) | 0x80;
            }
            else if (*pTempUTF16 >= 0x0800 && *pTempUTF16 <= 0xFFFF && pTempUTF8 + 3 < pUTF8End)
            {
                *pTempUTF8++ = (*pTempUTF16 >> 12) | 0xE0;
                *pTempUTF8++ = ((*pTempUTF16 >> 6) & 0x3F) | 0x80;
                *pTempUTF8++ = (*pTempUTF16 & 0x3F) | 0x80;
            }
            else
            {
                break;
            }

            pTempUTF16++;
        }
    }
}

struct monoString 
{
	void *klass;
	void *monitor;
	int length;
	char chars[1];

	int getLength() {
		return memory->read<int>((uint64_t)this + offsetof(struct monoString, length));
	}

    void getStringToBufferWithLength(char *out_buffer, int in_length) {
        uint16_t string_utf16_buffer[in_length];

        memory->readBuffer((uint64_t)this + offsetof(struct monoString, chars), sizeof(string_utf16_buffer), string_utf16_buffer);
        string_utf16_buffer[in_length - 1] = 0;
        out_buffer[in_length - 1] = 0;

        StringUtils::utf16_to_utf8((uint8_t *)out_buffer, in_length, string_utf16_buffer, in_length);
    }

	char *getString() {
		int string_size = this->getLength() * 2;
		char *string_buffer = (char *)safe_malloc(string_size + 2);
        if (!string_buffer)
            return strdup("Null");

		bzero(string_buffer, string_size + 2);
		memory->readBuffer((uint64_t)this + offsetof(struct monoString, chars), string_size, string_buffer);

		char *utf8_string = utf16_to_utf8(string_buffer, string_size);

	    free((void *)string_buffer);

	    return utf8_string;
	}
};

template<typename T>
struct monoArray 
{
    void *klass;
    void *monitor;
    void *bounds;
    int capacity;
    T items[1];

    int getLength() {
        return memory->read<int>((uint64_t)this + offsetof(struct monoArray, capacity));
    }

    T *getItemsBuffer() {
        int items_size = this->getLength() * sizeof(T);
        T *items_buffer = (T *)safe_malloc(items_size);

        bzero(items_buffer, items_size);
        memory->readBuffer((uint64_t)this + offsetof(struct monoArray, items), items_size, items_buffer);

        return items_buffer;
    }

    T *getItemsBufferWithLength(int length) {
        int items_size = length * sizeof(T);
        T *items_buffer = (T *)safe_malloc(items_size);

        bzero(items_buffer, items_size);
        memory->readBuffer((uint64_t)this + offsetof(struct monoArray, items), items_size, items_buffer);

        return items_buffer;
    }

    void getItemsToBufferWithLength(T *items_buffer, int length) {
        int items_size = length * sizeof(T);

        bzero(items_buffer, items_size);
        memory->readBuffer((uint64_t)this + offsetof(struct monoArray, items), items_size, items_buffer);
    }

    void setItemAtIndex(int index, T item) {
        uint64_t item_offset = index * sizeof(T);
        memory->write<T>((uint64_t)this + offsetof(struct monoArray, items) + item_offset, item);
    }
};

template<typename T>
struct monoList
{
    void *klass;
    void *monitor;
    monoArray<T> *items;
    int size;
    int version;

    int getLength() {
        return memory->read<int>((uint64_t)this + offsetof(struct monoList, size));
    }

    void getItemsToBufferWithLength(T *items_buffer, int length) {
        monoArray<T> *items_array = memory->read<monoArray<T> *>((uint64_t)this + offsetof(struct monoList, items));
        items_array->getItemsToBufferWithLength(items_buffer, length);
    }
};

template<typename TKey, typename TValue>
struct monoDictionary 
{

    struct Entry {
        int hashCode, next;
        TKey key;
        TValue value;
    };

    void *klass;
    void *monitor;
    monoArray<int> *buckets;
    monoArray<Entry> *entries;
    int count;

    int getLength() {
        return memory->read<int>((uint64_t)this + offsetof(struct monoDictionary, count));
    }

    Entry *getEntriesBuffer() {
        monoArray<Entry> *entries_array = memory->read<monoArray<Entry> *>((uint64_t)this + offsetof(struct monoDictionary, entries));
        return entries_array->getItemsBufferWithLength(this->getLength());
    }

    monoArray<Entry> *getEntriesArray() {
        return memory->read<monoArray<Entry> *>((uint64_t)this + offsetof(struct monoDictionary, entries));
    }

    void getEntriesToBufferWithLength(Entry *entries_buffer, int length) {
        monoArray<Entry> *entries_array = memory->read<monoArray<Entry> *>((uint64_t)this + offsetof(struct monoDictionary, entries));
        entries_array->getItemsToBufferWithLength(entries_buffer, length);
    }
};

struct Hashtable : monoDictionary<monoString *, uint64_t> 
{
    template<typename T>
    T getBoxedValueForKey(const char *key) {
        int entries_length = this->getLength();
        monoDictionary<monoString *, uint64_t>::Entry hashtable_entries[entries_length];
        this->getEntriesToBufferWithLength(hashtable_entries, entries_length);

        for(int i = 0; i < entries_length; i++) {
            monoString *current_entry_key = hashtable_entries[i].key;
            if (!current_entry_key)
                continue;

            char key_string[16];
            current_entry_key->getStringToBufferWithLength((char *)key_string, sizeof(key_string));

            if (strstr(key_string, key)) {
                T result = (T)hashtable_entries[i].value;
                return result;
            }
        } 

        return NULL;
    }

    template<typename T>
    T getUnboxedValueForKey(const char *key) {
        uint64_t boxed_value = this->getBoxedValueForKey<uint64_t>(key);
        return (boxed_value) ? memory->read<T>(boxed_value + 0x10) : NULL;
    }

};

//sizeof(TMartrix) == 0x30
struct TMatrix 
{
    Vector3 position;
    char pad1[4];
    Quaternion rotation;
    Vector3 scale;
    char pad2[4];
};

struct Transform 
{
    Vector3 getPosition() {
        uint64_t mono_object = memory->read<uint64_t>((uint64_t)this + 0x10);

        uint64_t g_matrix = memory->read<uint64_t>(mono_object + 0x38);
        uint64_t index_in_g_matrix = memory->read<uint64_t>(mono_object + 0x40);

        uint64_t matrix_list = memory->read<uint64_t>(g_matrix + 0x18);
        uint64_t matrix_indices = memory->read<uint64_t>(g_matrix + 0x20);

        Vector3 result = memory->read<Vector3>(matrix_list + sizeof(TMatrix) * index_in_g_matrix);
        int transformIndex = memory->read<int>(matrix_indices + sizeof(int) * index_in_g_matrix);

        while(transformIndex >= 0) {
            TMatrix tMatrix = memory->read<TMatrix>(matrix_list + sizeof(TMatrix) * transformIndex);
     
            float rotX = tMatrix.rotation.x;
            float rotY = tMatrix.rotation.y;
            float rotZ = tMatrix.rotation.z;
            float rotW = tMatrix.rotation.w;
     
            float scaleX = result.x * tMatrix.scale.x;
            float scaleY = result.y * tMatrix.scale.y;
            float scaleZ = result.z * tMatrix.scale.z;
     
            result.x = tMatrix.position.x + scaleX +
                        (scaleX * ((rotY * rotY * -2.0) - (rotZ * rotZ * 2.0))) +
                        (scaleY * ((rotW * rotZ * -2.0) - (rotY * rotX * -2.0))) +
                        (scaleZ * ((rotZ * rotX * 2.0) - (rotW * rotY * -2.0)));
            result.y = tMatrix.position.y + scaleY +
                        (scaleX * ((rotX * rotY * 2.0) - (rotW * rotZ * -2.0))) +
                        (scaleY * ((rotZ * rotZ * -2.0) - (rotX * rotX * 2.0))) +
                        (scaleZ * ((rotW * rotX * -2.0) - (rotZ * rotY * -2.0)));
            result.z = tMatrix.position.z + scaleZ +
                        (scaleX * ((rotW * rotY * -2.0) - (rotX * rotZ * -2.0))) +
                        (scaleY * ((rotY * rotZ * 2.0) - (rotW * rotX * -2.0))) +
                        (scaleZ * ((rotX * rotX * -2.0) - (rotY * rotY * 2.0)));
     
            transformIndex = memory->read<int>(matrix_indices + sizeof(int) * transformIndex);
        }
     
        return result;
    }

    void setPosition(const Vector3& newWorldPos) {
        uint64_t mono_object = memory->read<uint64_t>((uint64_t)this + 0x10);

        uint64_t w1 = memory->read<uint64_t>(mono_object + 0x38);
        uint64_t w2 = memory->read<uint64_t>(mono_object + 0x40);

        uint64_t w3 = memory->read<uint64_t>(w1 + 0x18);
        uint64_t w4 = memory->read<uint64_t>(w1 + 0x20);

        std::vector<int> chain;
        int current = memory->read<int>(w4 + sizeof(int) * w2);
        while (current >= 0)
        {
            chain.push_back(current);
            current = memory->read<int>(w4 + sizeof(int) * current);
        }

        Vector3 localPos = newWorldPos;

        for (auto it = chain.rbegin(); it != chain.rend(); ++it)
        {
            TMatrix parentMatrix = memory->read<TMatrix>(w3 + sizeof(TMatrix) * (*it));

            localPos.x -= parentMatrix.position.x;
            localPos.y -= parentMatrix.position.y;
            localPos.z -= parentMatrix.position.z;

            Quaternion invRot = Quaternion::Conjugate(parentMatrix.rotation);

            localPos = invRot * localPos; 

            if (fabs(parentMatrix.scale.x) > 1e-6f) localPos.x /= parentMatrix.scale.x;
            if (fabs(parentMatrix.scale.y) > 1e-6f) localPos.y /= parentMatrix.scale.y;
            if (fabs(parentMatrix.scale.z) > 1e-6f) localPos.z /= parentMatrix.scale.z;
        }

        TMatrix localMatrix = memory->read<TMatrix>(w3 + sizeof(TMatrix) * w2);
        localMatrix.position = localPos;
        memory->write<TMatrix>(w3 + sizeof(TMatrix) * w2, localMatrix);
    }
};
