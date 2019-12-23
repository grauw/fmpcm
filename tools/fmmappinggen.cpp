#include <cstdint>
#include <cmath>
#include <array>
#include <vector>
#include <iostream>
#include <sstream>
#include <iomanip>
#include <iterator>
#include <limits>

uint16_t expTable[256];
uint16_t logsinTable[256];

void initTables() {
	for (int i = 0; i < 256; ++i) {
		logsinTable[i] = round(-log2(sin((double(i) + 0.5) * M_PI / 256.0 / 2.0)) * 256.0);
		expTable[i] = round((exp2(double(i) / 256.0) - 1.0) * 1024.0);
	}
}

uint16_t lookupSin(uint16_t val) {
	bool sign   = val & 512;
	bool mirror = val & 256;
	val &= 255;
	uint16_t result = logsinTable[mirror ? val ^ 0xFF : val];
	if (sign) result |= 0x8000;
	return result;
}

int16_t lookupExp(uint16_t val) {
	bool sign = val & 0x8000;
	int t = (expTable[(val & 0xFF) ^ 0xFF] << 1) | 0x0800;
	int result = t >> ((val & 0x7F00) >> 8);
	if (sign) result = ~result;
	return result;
}

std::array<int32_t, 16> mltab = { 1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 20, 24, 24, 30, 30};

void calcChannel(std::array<int32_t, 8>& voice, std::array<int32_t, 256>& buffer)
{
	int32_t tl = voice[2] & 63;
	int32_t volume = 0;
	int32_t multM = mltab[voice[0] & 15];
	int32_t multC = mltab[voice[1] & 15];
	int32_t enableM = voice[0] >> 5 & 1;
	int32_t block = 7;

	for (uint32_t fnum = 0; fnum < 256; fnum++) {
		uint32_t phase = fnum << block;
		auto sinM = lookupSin(phase * multM >> 10);
		auto modulator = lookupExp(sinM + 16 * 2 * tl) >> 1;
		auto sinC = lookupSin((phase * multC >> 10) + (enableM ? 2 * modulator : 0));
		auto carrier = lookupExp(sinC + 16 * 8 * volume) >> 4;
		buffer[fnum] = carrier;
	}
}

std::array<int32_t, 256> getMapping(std::array<int32_t, 256>& buffer)
{
	int32_t min = std::numeric_limits<int32_t>::max();
	int32_t max = std::numeric_limits<int32_t>::min();
	for (auto i : buffer)
	{
		min = std::min(i, min);
		max = std::max(i, max);
	}
	std::array<int32_t, 256> mapping {};
	for (int32_t i = -128; i < 128; i++)
	{
		double closestDistance = std::numeric_limits<double>::max();
		int32_t closestFnumLSB = -1;
		for (int32_t j = 0; j < 256; j++)
		{
			double distance = fabs((buffer[j] - min) / float(max - min) - (i + 128) / 255.0);
			if (distance < closestDistance)
			{
				closestDistance = distance;
				closestFnumLSB = j;
			}
		}
		mapping[i & 0xFF] = closestFnumLSB;
	}
	return mapping;
}

std::array<double, 256> getDistances(std::array<int32_t, 256>& buffer)
{
	int32_t min = std::numeric_limits<int32_t>::max();
	int32_t max = std::numeric_limits<int32_t>::min();
	for (auto i : buffer)
	{
		min = std::min(i, min);
		max = std::max(i, max);
	}
	std::array<double, 256> distances {};
	for (int32_t i = -128; i < 128; i++)
	{
		double closestDistance = std::numeric_limits<double>::max();
		int32_t closestFnumLSB = -1;
		for (int32_t j = 0; j < 256; j++)
		{
			double distance = fabs((buffer[j] - min) / float(max - min) - (i + 128) / 255.0);
			if (distance < closestDistance)
			{
				closestDistance = distance;
				closestFnumLSB = j;
			}
		}
		distances[i & 0xFF] = closestDistance * 127.5;
	}
	return distances;
}

template<class T> std::string arrtos(T& buffer)
{
	std::ostringstream output;
	std::copy(buffer.begin(), buffer.end(), std::ostream_iterator<int32_t>(output, ", "));
	return output.str();
}

template<class T> std::string arrtohs(T& buffer)
{
	std::ostringstream output;
	for (auto i : buffer)
	{
		output << std::setw(2) << std::setfill('0') << std::hex << i << " ";
	}
	return output.str();
}

template<class T> std::string arrtofs(T& buffer)
{
	double total;
	std::ostringstream output;
	for (auto i : buffer)
	{
		output << std::fixed << std::setprecision(1) << i << " ";
		total += i;
	}
	output << "-- Total: " << total;
	return output.str();
}

std::array<int32_t, 256> getMappingCounts(std::array<int32_t, 256> mapping)
{
	std::array<int32_t, 256> mappingCounts {};
	for (int32_t map : mapping)
		mappingCounts[map]++;
	return mappingCounts;
}

int32_t getUnique(std::array<int32_t, 256> mappingCounts)
{
	int32_t unique = 0;
	for (int32_t count : mappingCounts)
		if (count > 0) unique++;
	return unique;
}

void testMapping()
{
	std::array<int32_t, 256> buffer {};
	std::array<int32_t, 8> voice { 0x00, 0x24, 0x3F, 0x00, 0xFF, 0xFF, 0x0F, 0x0F };

	calcChannel(voice, buffer);

	auto mapping = getMapping(buffer);
	auto distances = getDistances(buffer);
	auto mappingCounts = getMappingCounts(mapping);
	int32_t unique = getUnique(mappingCounts);

	std::cout << "Voice: " << arrtohs(voice) << std::endl << std::endl;
	std::cout << "Amplitudes: " << arrtos(buffer) << std::endl << std::endl;
	std::cout << "Mapping: " << arrtos(mapping) << std::endl << std::endl;
	std::cout << "Distances: " << arrtofs(distances) << std::endl << std::endl;
	std::cout << "Counts: " << arrtos(mappingCounts) << std::endl << std::endl;
	std::cout << "Unique: " << unique << std::endl;
}

void testCombinations()
{
	std::array<int32_t, 256> buffer {};
	std::array<int32_t, 8> voice { 0x20, 0x2F, 0x1D, 0x00, 0xFF, 0xFF, 0x0F, 0x0F };
	for (int32_t m = 0; m < 16; m++)
	{
		if (m == 11 || m == 13 || m == 14) continue;
		voice[0] = m | 0x20;
		for (int32_t c = 0; c < 16; c++)
		{
			if (c == 11 || c == 13 || c == 14) continue;
			voice[1] = c | 0x20;
			for (int32_t tl = 0; tl < 63; tl++)
			{
				voice[2] = tl;
				calcChannel(voice, buffer);
				auto mapping = getMapping(buffer);
				auto distances = getDistances(buffer);
				auto mappingCounts = getMappingCounts(mapping);
				int32_t unique = getUnique(mappingCounts);

				if (unique >= 200)
				{
					std::cout << "Voice: " << arrtohs(voice) << std::endl << std::endl;
					std::cout << "Amplitudes: " << arrtos(buffer) << std::endl << std::endl;
					std::cout << "Mapping: " << arrtos(mapping) << std::endl << std::endl;
					std::cout << "Distances: " << arrtofs(distances) << std::endl << std::endl;
					std::cout << "Counts: " << arrtos(mappingCounts) << std::endl << std::endl;
					std::cout << "Unique: " << unique << std::endl;
				}
			}
		}
	}
}

int main()
{
	initTables();
	testMapping();
	// testCombinations();
}
